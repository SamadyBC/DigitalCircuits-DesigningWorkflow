# 1. Fechar simulações anteriores abertas se houver alguma
if {[workenv] != ""} {
    quit -sim
}

# 2. Resetar a biblioteca work
if [file exists work] {
    vdel -all
}
vlib work
vmap work work

# 3. Compilando Arquivos
puts "-- Compilando Arquivos --"
vlog rsa_core_mult.sv
vlog rsa_core_mod.sv
vlog rsa_core_ctrl.sv
vlog rsa_core.sv
vlog rsa_io.sv
vlog rsa_top.sv

# 4. Iniciar a simulação (Ajustado: removido o ".sv" para referenciar o módulo)
vsim work.rsa_top

# Adicionar todos os sinais da raiz na janela de forma de onda
add wave *

# ==============================================================================
# 5. BLOCO DE ESTÍMULOS (Seu Testbench em Tcl)
# ==============================================================================
puts "-- Iniciando os Estímulos via Script --"


#Definicao Clock
force -freeze sim:/rsa_top/clk 0 0 ns, 1 5 ns -repeat 10 ns

#Cenario teste 1 - dada a implementacao o reset faz parte de todos os cenarios
force sim:/rsa_top/rst 1

run 20ns

force sim:/rsa_top/rst 0

run 20ns

force sim:/rsa_top/data_in 2#0010

force sim:/rsa_top/btn_load 2#1

run 10ns

force sim:/rsa_top/btn_load 2#0

run 10ns

force sim:/rsa_top/data_in 2#0011

force sim:/rsa_top/btn_load 2#1

run 10ns 

force sim:/rsa_top/btn_load 2#0

run 10ns

force sim:/rsa_top/data_in 2#0101

force sim:/rsa_top/btn_load 2#1

run 10ns

force sim:/rsa_top/btn_load 2#0

run 10ns

force sim:/rsa_top/rst 1

run 10ns
