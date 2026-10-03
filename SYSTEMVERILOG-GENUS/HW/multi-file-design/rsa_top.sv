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