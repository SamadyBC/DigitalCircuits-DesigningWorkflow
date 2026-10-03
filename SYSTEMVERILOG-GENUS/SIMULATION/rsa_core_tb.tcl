
# Fechar simulacoes anteriores abertas se houver alguma
if {[workenv] != ""} {
	quit -sim
}

if [file exists work] {
	vdel -all
}
vlib work

vmap work work

puts "-- Compilando Arquivos --"
vlog rsa_core_mult.sv
vlog rsa_core_mod.sv
vlog rsa_core_ctrl.sv
vlog rsa_core.sv
vlog rsa_io.sv
vlog rsa_top.sv

vsim work.rsa_top

add wave *


