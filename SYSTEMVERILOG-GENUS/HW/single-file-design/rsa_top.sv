module rsa_top (
    input logic clk, 
    input logic rst, 
    input logic btn_load,
    input logic [3:0] data_in, 
    output logic core_clk_o,
    output logic [6:0] s,  
    output logic led_m, 
    output logic led_e, 
    output logic led_n, 
    output logic led_calc,
    output logic [6:0] m
);

    logic w_io_load;
    logic [3:0] w_io_din;
    logic w_core_done;
    logic w_core_err;
    logic [3:0] w_core_dout;

    rsa_core #(
        .DATA_WIDTH(4),
        .RESET(1'b1),
        .LOAD(1'b1)
    ) U0 (
        .core_clk(clk), 
        .core_rst(rst), 
        .core_load(w_io_load),   // Controlado pelo rsa_io
        .core_din(w_io_din),     // Controlado pelo rsa_io
        .core_clk_o(core_clk_o), 
        .core_done(w_core_done), // Retorna para o rsa_io
        .core_err(w_core_err),   // Retorna para o rsa_io
        .core_dout(w_core_dout)  // Retorna para o rsa_io
    );

    rsa_io U1 (
        .clk(clk), 
        .rst(rst), 
        .btn_enter(btn_load), 
        .sw_din(data_in), 
        .core_done(w_core_done), // Entradas que represetam as saidas da operacao
        .core_err(w_core_err),
        .core_dout(w_core_dout),
        .io_load(w_io_load),     // FSM comanda o load do core
        .io_din(w_io_din),       // FSM repassa as chaves
        .s(s),
        .led_m(led_m), .led_e(led_e), .led_n(led_n), .led_calc(led_calc),
        .m(m)
    );
    
endmodule

// ============================================================
// Module: rsa_io
// ============================================================
module rsa_io (
    input logic clk, rst, btn_enter,
    input logic [3:0] sw_din,
    input logic core_done, core_err,
    input logic [3:0] core_dout,
    
    output logic io_load,
    output logic [3:0] io_din,
    output logic [6:0] s,
    
    output logic led_m, led_e, led_n, led_calc,
    output logic [6:0] m
);

    typedef enum logic [3:0] {
        w_m = 4'b0000,
        l_m = 4'b0001,
        w_e = 4'b0010,
        l_e = 4'b0011,
        w_n = 4'b0100,
        l_n = 4'b0101,
        cal = 4'b0110,
        sw_error = 4'b0111,
        sw_res = 4'b1000
    } state_t;

    state_t current_state;
    state_t next_state;
    logic [3:0] display_data; 
    logic [6:0] display_error;

    assign m = display_error;

    // 1. Registrador de estado com reset assíncrono ativo em nível alto
    always_ff @(posedge clk or posedge rst) begin
        if (rst) current_state <= w_m;
        else current_state <= next_state;
    end
        
    // 2. LÓGICA DE PRÓXIMO ESTADO
    always_comb begin
        next_state = current_state; // Valor padrão evita latches indesejados
        case (current_state)
            w_m: begin
              if (btn_enter == 1'b1)
                next_state = l_m;
              else
                next_state = w_m;
            end
            l_m: begin
              if (btn_enter == 1'b0) 
                next_state = w_e;
              else
                next_state = l_m;
            end
            w_e: begin
                if (btn_enter == 1'b1) 
                next_state = l_e;
                else
                next_state = w_e;
                end
            l_e: begin
              if (btn_enter == 1'b0) 
                next_state = w_n;
              else
                next_state = l_e;
            end
            w_n: begin
              if (btn_enter == 1'b1)
                next_state = l_n;
              else
                next_state = w_n;
            end
            l_n: begin
              if (btn_enter == 1'b0)
                next_state = cal; 
              else
                next_state = l_n;
            end
            cal: begin
                if (core_done == 1'b1) begin
                    if (core_err == 1'b1) next_state = sw_error;
                    else next_state = sw_res;
                end
            end
            sw_error: next_state = sw_error; // Fica aqui até o rst
            sw_res: next_state = sw_res;     // Fica aqui até o rst
            default: next_state = w_m;
        endcase
    end
    
    // 3. LÓGICA DE SAÍDA
    always_comb begin
        
        io_load = 1'b0;
        io_din = sw_din;
        display_data = sw_din;
        display_error = 7'b0000000;
        led_m = 1'b0; 
        led_e = 1'b0; 
        led_n = 1'b0; 
        led_calc = 1'b0;

        case (current_state)
            w_m: ;
            l_m: begin 
                io_load = 1'b1; 
                led_m = 1'b1; 
            end
            w_e: begin 
                led_m = 1'b1; 
            end
            l_e: begin 
                io_load = 1'b1; 
                led_m = 1'b1; 
                led_e = 1'b1; 
            end
            w_n: begin 
                led_m = 1'b1; 
                led_e = 1'b1; 
            end
            l_n: begin 
                io_load = 1'b1; 
                led_m = 1'b1; 
                led_e = 1'b1; 
                led_n = 1'b1; 
            end
            cal: begin 
                led_m = 1'b1; 
                led_e = 1'b1; 
                led_n = 1'b1; 
                led_calc = 1'b1;
            end
            sw_res: begin 
                led_m = 1'b1; 
                led_e = 1'b1; 
                led_n = 1'b1;
                display_data = core_dout; 
            end
            sw_error: begin
                led_m = 1'b1; 
                led_e = 1'b1; 
                led_n = 1'b1;
                // Deixa o display livre para mostrarmos o "E" no decodificador
                display_error = 7'b1001111;
            end
        endcase
    end
    
    // 4. DECODIFICADOR DO DISPLAY 7 SEGMENTOS
    always_comb begin
        if (current_state == sw_error)
          begin
            s = 7'b0000000; // Mantém este display apagado durante o estado de erro
          end
        else begin 
            // O decodificador agora lê a variável 'display_data'
            case (display_data)
                4'b0000: s = 7'b1111110;
                4'b0001: s = 7'b0110000;
                4'b0010: s = 7'b1101101;
                4'b0011: s = 7'b1111001;
                4'b0100: s = 7'b0110011;
                4'b0101: s = 7'b1011011;
                4'b0110: s = 7'b1011111;
                4'b0111: s = 7'b1110000;
                4'b1000: s = 7'b1111111;
                4'b1001: s = 7'b1111011;
                4'b1010: s = 7'b1110111;
                4'b1011: s = 7'b0011111;
                4'b1100: s = 7'b1001110;
                4'b1101: s = 7'b0111101;
                4'b1110: s = 7'b1001111;
                4'b1111: s = 7'b1000111;
                default: s = 7'b0000000;
            endcase
        end
    end
endmodule

module rsa_core_mod #(
    parameter DATA_WIDTH = 4,
    parameter RESET      = 1,   // Nivel de reset ativo
    parameter START      = 1    // Nivel ativo para mod_start
)(
    input logic                        mod_clk,
    input logic                        mod_rst,
    input logic                        mod_start,
    input logic     [2*DATA_WIDTH-1:0] mod_a,
    input logic     [DATA_WIDTH-1:0]   mod_b,
    output logic                       mod_done,
    output logic                       mod_err,
    output logic    [DATA_WIDTH-1:0]   mod_c
);

  // Definicao dos estados da FSM (8 estados)
  localparam logic INIT     = 3'b000,
             CHECK    = 3'b001,
             PREPARE  = 3'b010,
             COMPARE  = 3'b011,
             SUBTRACT = 3'b100,
             SHIFT    = 3'b101,
             DONE     = 3'b110,
             ERROR    = 3'b111;

  // Declaracaoo dos sinais internos
  logic [2:0] state_reg;
  logic	[2:0] state_ns;
  logic	[DATA_WIDTH:0] a_cnt;
  logic	[2*DATA_WIDTH-1:0] t_reg, n_reg;
  logic	[DATA_WIDTH-1:0] r_reg;
  logic	mod_done_ff, mod_err_ff;

  // Atribuicao das saidas
  assign mod_done = mod_done_ff;
  assign mod_err  = mod_err_ff;
  assign mod_c    = r_reg;

  // Logica combinacional para o calculo do proximo estado (FSM)
  always_comb begin
    if (mod_rst == RESET)
      state_ns = INIT;
    else begin
      case (state_reg)
        INIT: begin
          if (mod_start == START)
            state_ns = CHECK;
          else
            state_ns = INIT;
        end
        CHECK: begin
          if (n_reg[DATA_WIDTH-1:0] == {DATA_WIDTH{1'b0}})
            state_ns = ERROR;
          else
            state_ns = PREPARE;
        end
        PREPARE: begin
          if (n_reg[2*DATA_WIDTH-2] == 1'b0)
            state_ns = PREPARE;
          else
            state_ns = COMPARE;
        end
        COMPARE: begin
          if (t_reg >= n_reg)
            state_ns = SUBTRACT;
          else
            state_ns = SHIFT;
        end
        SUBTRACT: begin
          if (a_cnt != 0)
            state_ns = COMPARE;
          else
            state_ns = DONE;
        end
        SHIFT: begin
          if (a_cnt != 0)
            state_ns = COMPARE;
          else
            state_ns = DONE;
        end
        DONE:
        	state_ns = INIT;
        ERROR:
        	state_ns = INIT;
        default: state_ns = INIT;
      endcase
    end
  end

  // Bloco sequencial acionado na borda de subida do clock
      always_ff @(posedge mod_clk) begin
        case (state_reg)
          INIT: begin
            mod_done_ff <= 1'b0;
            t_reg       <= mod_a;
            n_reg[DATA_WIDTH-1:0] <= mod_b;
            n_reg[2*DATA_WIDTH-1:DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
            a_cnt       <= {DATA_WIDTH+1{1'b0}};
          end
          CHECK: begin
            // Nada a transferir nesta fase
          end
          PREPARE: begin
            a_cnt <= a_cnt + 1'b1;
            n_reg <= { n_reg[2*DATA_WIDTH-2:0], 1'b0 };
          end
          COMPARE: begin
            // Nenhuma transferencia nesta fase
          end
          SUBTRACT: begin
            t_reg <= t_reg - n_reg;
            n_reg <= { 1'b0, n_reg[2*DATA_WIDTH-1:1] };
            a_cnt <= a_cnt - 1'b1;
          end
          SHIFT: begin
            n_reg <= { 1'b0, n_reg[2*DATA_WIDTH-1:1] }; //Essa sintaxe representa um rigth shift?
            a_cnt <= a_cnt - 1'b1; // Por que diminui 1b do contador?
          end
          DONE: begin
            r_reg       <= t_reg[DATA_WIDTH-1:0];
            mod_done_ff <= 1'b1;
            mod_err_ff  <= 1'b0;
          end
          ERROR: begin
            mod_err_ff  <= 1'b1;
            mod_done_ff <= 1'b1;
            r_reg       <= {DATA_WIDTH{1'b1}};
          end
          default: begin
            // Nao faz nada
          end
        endcase
        state_reg <= state_ns;
      end
endmodule

module rsa_core_ctrl #(
    parameter DATA_WIDTH = 4,
    parameter RESET = 1'b1,
    parameter LOAD = 1'b1
)(
    input logic ctrl_clk,
    input logic ctrl_rst,
    input logic ctrl_load,
    input logic [DATA_WIDTH-1:0] ctrl_din,
    input logic ctrl_loadx,
    input logic [DATA_WIDTH-1:0] ctrl_dinx,
    output logic ctrl_done,
    output logic ctrl_err,
    output logic [DATA_WIDTH-1:0] ctrl_c,
    output logic ctrl_start,
    output logic [DATA_WIDTH-1:0] ctrl_n,
    output logic [DATA_WIDTH-1:0] ctrl_m,
    output logic [DATA_WIDTH-1:0] ctrl_doutx
);

    localparam logic [DATA_WIDTH-1:0] ONE = 'd1;
    
    localparam logic [3:0] 
        INIT    = 4'd0,
        LOAD_M  = 4'd1,
        WAIT_M  = 4'd2,
        LOAD_E  = 4'd3,
        WAIT_E  = 4'd4,
        LOAD_N  = 4'd5,
        WAIT_N  = 4'd6,
        ERROR   = 4'd7,
        CASE0   = 4'd8,
        ANALYZE = 4'd9,
        DONE    = 4'd10,
        CASE1   = 4'd11,
        CASE2   = 4'd12,
        START   = 4'd13;
    
    logic    	[3:0]state_reg;
    logic		[3:0]state_ns;
    
    logic [DATA_WIDTH-1:0] n_reg;
    logic [DATA_WIDTH-1:0] e_reg;
    logic [DATA_WIDTH-1:0] m_reg;
    logic [DATA_WIDTH-1:0] x_reg;
    logic [DATA_WIDTH-1:0] c_reg;
    logic err_ff;
    logic start_ff;
    logic done_ff;
    
    assign ctrl_c = c_reg;
    assign ctrl_n = n_reg;
    assign ctrl_m = m_reg;
    assign ctrl_doutx = x_reg;
    
    assign ctrl_done = done_ff;
    assign ctrl_start = start_ff;
    assign ctrl_err = err_ff;
    
    always_comb begin
    	if (ctrl_rst == RESET)
			state_ns = INIT;
    	else
        	case (state_reg)
        	    INIT:
        	    	state_ns = LOAD_M;        	    	
        	    LOAD_M:
        	    	state_ns = (ctrl_load == LOAD) ? WAIT_M : LOAD_M;
        	    WAIT_M:
        	    	state_ns = (ctrl_load == LOAD) ? WAIT_M : LOAD_E;
        	    LOAD_E:
        	    	state_ns = (ctrl_load == LOAD) ? WAIT_E : LOAD_E;
        	    WAIT_E:
        	    	state_ns = (ctrl_load == LOAD) ? WAIT_E : LOAD_N;
        	    LOAD_N:
        	    	state_ns = (ctrl_load == LOAD) ? WAIT_N : LOAD_N;
        	    WAIT_N: begin
        	        if (ctrl_load == LOAD)
        	            state_ns = WAIT_N;
        	        else if (n_reg == 0)
        	            state_ns = ERROR;
        	        else if (e_reg == 0)
        	            state_ns = CASE0;
        	        else if (e_reg == 1)
        	            state_ns = CASE1;
        	        else
        	            state_ns = CASE2;
        	    end
        	    ERROR:
        	    	state_ns = LOAD_M;
        	    CASE0:
        	    	state_ns = ANALYZE;
        	    
        	    ANALYZE: begin
        	        if (!ctrl_loadx)
        	            state_ns = ANALYZE;
        	        else
        	        	if (e_reg == 0)
        	            	state_ns = DONE;
	        	        else
        	            	state_ns = START;
        	    end
        	    DONE:
        	    	state_ns = LOAD_M;
        	    CASE1:
        	    	state_ns = ANALYZE;
        	    CASE2:
        	    	state_ns = ANALYZE;
        	    START:
        	    	state_ns = ANALYZE;
        	    default:
        	    	state_ns = INIT;
        	endcase
    end
    
    always_ff @(posedge ctrl_clk) begin
		case (state_reg)
        	INIT: begin
            	err_ff		<= 1'b0;
                start_ff	<= 1'b0;
                done_ff		<= 1'b0;
        	end
			LOAD_M: begin
            	m_reg 		<= ctrl_din;
                x_reg 		<= ctrl_din;
                done_ff 	<= 1'b0;
            end
            WAIT_M:begin
            end
            LOAD_E:
            	e_reg 		<= ctrl_din;
            WAIT_E:begin
            end
			LOAD_N:
				n_reg 		<= ctrl_din;
            ERROR: begin
            	done_ff 	<= 1'b1;
                err_ff 		<= 1'b1;
                c_reg 		<= {DATA_WIDTH{1'b1}};
            end
            CASE0: begin
				start_ff	<= 1'b1;
				m_reg		<= ONE;
				x_reg		<= ONE;
			end
			ANALYZE: begin
				x_reg		<= ctrl_dinx;
				start_ff	<= 1'b0;
			end	
			DONE: begin
				c_reg		<= x_reg;
				done_ff		<= 1'b1;
				err_ff		<= 1'b0;				
			end	
			CASE1: begin
				start_ff	<= 1'b1;
				x_reg		<= ONE;
				e_reg		<= e_reg - 1;
			end
			CASE2: begin
				start_ff	<= 1'b1;
				e_reg		<= e_reg - 2;
			end
			START: begin
				start_ff	<= 1'b1;
				e_reg		<= e_reg - 1;
            end
		endcase
        state_reg <= state_ns;
    end
endmodule

module rsa_core #(
    parameter DATA_WIDTH = 4,
    parameter RESET = 1'b1,
    parameter LOAD = 1'b1
)
(
    input logic                     core_clk,
    input logic                     core_rst,
    input logic                     core_load,
    input logic  [DATA_WIDTH-1:0]   core_din,
    output logic                    core_done,
    output logic                    core_err,
    output logic [DATA_WIDTH-1:0]   core_dout,
    output logic                    core_clk_o
);

    assign core_clk_o = core_clk;

    // Internal signals
    logic ctrl_start_sig;
    logic [DATA_WIDTH-1:0] ctrl_m_sig;
    logic [DATA_WIDTH-1:0] ctrl_n_sig;
    logic [DATA_WIDTH-1:0] ctrl_doutx_sig;

    logic mult_done_sig;
    logic [2*DATA_WIDTH-1:0] mult_c_sig;

    logic mod_done_sig;
    logic [DATA_WIDTH-1:0] mod_c_sig;

    // Component instantiations
    rsa_core_mult #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESET(RESET),
        .START(1'b1)
    ) rsa_core_mult_blk (
        .mult_clk(core_clk),
        .mult_rst(core_rst),
        .mult_start(ctrl_start_sig),
        .mult_a(ctrl_m_sig),
        .mult_b(ctrl_doutx_sig),
        .mult_done(mult_done_sig),
        .mult_c(mult_c_sig)
    );

    rsa_core_mod #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESET(RESET),
        .START(1'b1)
    ) rsa_core_mod_blk (
        .mod_clk(core_clk),
        .mod_rst(core_rst),
        .mod_start(mult_done_sig),
        .mod_a(mult_c_sig),
        .mod_b(ctrl_n_sig),
        .mod_done(mod_done_sig),
        .mod_err(), // Deixe isso desconectado apenas se for realmente necessário
        .mod_c(mod_c_sig)
    );

    rsa_core_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESET(RESET),
        .LOAD(LOAD)
    ) rsa_core_ctrl_blk (
        .ctrl_clk(core_clk),
        .ctrl_rst(core_rst),
        .ctrl_load(core_load),
        .ctrl_din(core_din),
        .ctrl_loadx(mod_done_sig),
        .ctrl_dinx(mod_c_sig),
        .ctrl_done(core_done),
        .ctrl_err(core_err),
        .ctrl_c(core_dout),
        .ctrl_start(ctrl_start_sig),
        .ctrl_n(ctrl_n_sig),
        .ctrl_m(ctrl_m_sig),
        .ctrl_doutx(ctrl_doutx_sig)
    );

endmodule

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