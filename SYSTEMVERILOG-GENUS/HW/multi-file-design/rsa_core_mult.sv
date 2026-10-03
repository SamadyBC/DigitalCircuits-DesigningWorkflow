module rsa_core_mult #(
  parameter DATA_WIDTH = 4,
  parameter RESET      = 1,
  parameter START      = 1
) (
    input  logic                     mult_clk,
    input  logic                     mult_rst,
    input  logic                     mult_start,
    input  logic [DATA_WIDTH-1:0]    mult_a,
    input  logic [DATA_WIDTH-1:0]    mult_b,
    output logic                     mult_done,
    output logic [2*DATA_WIDTH-1:0]  mult_c
);
  // Explicitly size the state constants as 3-bit numbers
  	localparam [2:0]INIT      = 3'd0,
                  	ANALYZE   = 3'd1,
                   	SHIFT_ADD = 3'd2,
                   	SHIFT     = 3'd3,
                   	DONE      = 3'd4;

 	logic [2:0] state_reg;
 	logic [2:0] state_ns;
  	logic [$clog2(DATA_WIDTH+1)-1:0] a_cnt;
  	logic [DATA_WIDTH-1:0] a_reg, b_reg;
 	logic [2*DATA_WIDTH-1:0] p_reg, c_reg;
  	logic done_ff;

	// OUTPUT SIGNALS CONNECTIONS
   	assign mult_done = done_ff;
  	assign mult_c    = c_reg;

	// NEXT STATE DECODE LOGIC
	always_comb begin
		if (mult_rst == RESET)
	    	state_ns = INIT;
	    else begin
	     	case(state_reg)
		        INIT:
		        	state_ns = (mult_start == START) ? ANALYZE : INIT;
		        	
		        ANALYZE:
		        	state_ns = (b_reg[DATA_WIDTH-1]) ? SHIFT_ADD : SHIFT;
		        	
		        SHIFT_ADD: begin
		          if (a_cnt != (DATA_WIDTH-1))
		            state_ns = (b_reg[DATA_WIDTH-1]) ? SHIFT_ADD : SHIFT;
		          else
		            state_ns = DONE;
		        end
		        
		        SHIFT: begin
		          if (a_cnt != (DATA_WIDTH-1))
		            state_ns = (b_reg[DATA_WIDTH-1]) ? SHIFT_ADD : SHIFT;
		          else
		            state_ns = DONE;
		        end
		        
		        DONE:
		        	state_ns = INIT;
		        default:
		        	state_ns = INIT;
	    	endcase
	    end
	  end

	always_ff @(posedge mult_clk) begin
    	case(state_reg)
        	INIT: begin
				p_reg   <= 0;
				a_cnt   <= 0;
				done_ff <= 1'b0;
				a_reg   <= mult_a;
				b_reg   <= mult_b;
        	end
			ANALYZE: begin
				b_reg <= {b_reg[DATA_WIDTH-2:0], 1'b0};
			end
			SHIFT_ADD: begin
				p_reg <= a_reg + {p_reg[2*DATA_WIDTH-2:0], 1'b0};
				a_cnt <= a_cnt + 1'b1;
				b_reg <= {b_reg[DATA_WIDTH-2:0], 1'b0};
			end
			SHIFT: begin
				p_reg <= {p_reg[2*DATA_WIDTH-2:0], 1'b0};
				a_cnt <= a_cnt + 1'b1;
				b_reg <= {b_reg[DATA_WIDTH-2:0], 1'b0};
			end
			DONE: begin
				done_ff <= 1'b1;
				c_reg   <= p_reg;
			end
		endcase
		state_reg <= state_ns;
	end
endmodule