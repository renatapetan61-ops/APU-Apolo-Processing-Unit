# APU — Unidade de Processamento Apolo

**APU (Unidade de Processamento Apolo)** é um projeto experimental de acelerador digital especializado em operações matemáticas usadas por Transformers e LLMs.

> Estado atual: protótipo RTL v0.1. Este repositório não contém um chip físico, não é ainda um treinador completo de LLMs e não reivindica desempenho 10× superior a uma TPU.

## Plataforma de desenvolvimento
- Host: Motorola Android
- Ambiente: Ubuntu dentro do Termux
- HDL: SystemVerilog
- Verificação: Python 3 + Icarus Verilog
- Primeira unidade: MAC INT8 com acumulador INT32

## Conteúdo
- `rtl/apu_mac.sv`: multiplicador-acumulador assinado INT8 × INT8 → INT32.
- `tb/tb_apu_mac.sv`: testbench SystemVerilog autochecking.
- `tests/test_apu_mac_reference.py`: testes de referência aritmética em Python.
- `Makefile`: comandos para executar os testes.

## Instalação no Ubuntu/Termux
```bash
apt update
apt install -y python3 make iverilog
```

## Testes
Na raiz do repositório:
```bash
python3 -m unittest discover -s tests -v
make rtl-test
```

O teste RTL requer Icarus Verilog. Alternativamente:
```bash
iverilog -g2012 -o /tmp/apu_mac_tb rtl/apu_mac.sv tb/tb_apu_mac.sv
vvp /tmp/apu_mac_tb
```

## Comportamento do MAC
Em cada borda de subida do clock:
- `rst=1`: limpa o acumulador (reset síncrono ativo em nível alto).
- `valid=0`: mantém o acumulador.
- `valid=1, clear=1`: substitui o acumulador pelo produto com extensão de sinal.
- `valid=1, clear=0`: soma o produto ao acumulador.

O acumulador opera em complemento de dois de 32 bits; overflow é wraparound módulo 2³².

## Arquitetura e roteiro
1. **v0.1 — MAC INT8:** datapath, testbench e referência Python.
2. **v0.2 — PE + array sistólico 4×4:** 16 elementos de processamento e verificação ciclo a ciclo.
3. **v0.3 — GEMM tiled:** interface de matrizes, controle de fluxo e contabilização de tráfego de memória.
4. **v0.4 — treinamento experimental:** escalas de quantização e experimentos numéricos.
5. **v0.5 — primitivas de treinamento:** gradientes e atualização de pesos, comparados a uma referência Python.
6. **Futuro — FPGA:** síntese, temporização, área e potência.

## Limites e critérios de desempenho
O Motorola é o host de desenvolvimento, não o acelerador físico. Para executar o RTL como hardware será necessário sintetizá-lo para FPGA ou um processo de fabricação apropriado. Uma meta de 10× só poderá ser avaliada contra uma TPU específica, com mesmo modelo, precisão, batch, sequência, qualidade numérica e medição de energia/latência.

## Verificação
Os testes Python verificam o modelo aritmético de referência. O testbench SystemVerilog precisa ser executado com Icarus Verilog. Testes aprovados não demonstram, por si só, síntese, frequência física, potência ou desempenho de TPU.
