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