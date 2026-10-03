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