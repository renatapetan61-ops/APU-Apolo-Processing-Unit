# APU — Unidade de Processamento Apolo

**APU (Unidade de Processamento Apolo)** é um projeto experimental de acelerador digital para operações matemáticas usadas por Transformers e LLMs.

> Estado atual: RTL experimental v0.2. O repositório não contém um chip físico nem um treinador completo de LLMs. Não há alegação comprovada de desempenho 10× superior a uma TPU.

## Plataforma de desenvolvimento
- Host: Motorola Android
- Ambiente: Ubuntu dentro do Termux
- HDL: SystemVerilog
- Verificação: Python 3 + Icarus Verilog
- Dados: INT8 assinado, acumuladores INT32

## Arquitetura v0.2
- Grade 4×4 com 16 elementos MAC independentes e pipeline local por PE.
- Cada PE registra o produto INT8×INT8 (estágio 1) e acumula o produto registrado em INT32 (estágio 2).
- Nesta V0.2, os operandos são selecionados/broadcast pelo controlador a partir das matrizes registradas; o encaminhamento físico PE-a-PE de uma matriz sistólica clássica ainda não está implementado. Essa será uma evolução posterior.
- Controlador GEMM 4×4 com fases IDLE, CLEAR_ACC, FEED, DRAIN e DONE.
- Uma operação calcula C=A×B para matrizes 4×4.
- Latência de projeto: 7 ciclos de clock da aceitação de START até DONE.
- Intervalo mínimo de iniciação: 7 ciclos quando uma nova solicitação é apresentada no ciclo DONE.
- Matrizes empacotadas em ordem row-major, elemento de índice zero nos bits menos significativos.

### Mapeamento de portas
- A[r,k] = `a_matrix[((r*4+k)*8) +: 8]`
- B[k,c] = `b_matrix[((k*4+c)*8) +: 8]`
- C[r,c] = `c_matrix[((r*4+c)*32) +: 32]`

## Arquivos principais
- `rtl/apu_mac.sv`: MAC sequencial original v0.1.
- `rtl/apu_systolic_array_4x4.sv`: 16 PEs com pipeline de produto e acumulação.
- `rtl/apu_matrix_controller.sv`: controlador de matriz 4×4.
- `tb/tb_apu_gemm4x4.sv`: teste de identidade, latência e solicitações consecutivas.
- `tb/tb_apu_overflow.sv`: teste RTL de wraparound INT32.
- `tests/test_apu_mac_reference.py`: referência aritmética v0.1.
- `tests/test_apu_gemm_reference.py`: testes Python de GEMM, INT8 e overflow.
- `tests/run_python_rtl_crosscheck.py`: gera 16 casos determinísticos e compara Python com simulação RTL.
- `Makefile`: comandos de verificação.

## Instalação no Ubuntu/Termux
```bash
apt update
apt install -y python3 make iverilog
```

## Executar verificação
```bash
make test
make rtl-test
make overflow-test
make crosscheck
```
Ou executar tudo:
```bash
make all
```

O teste cruzado compila o RTL com Icarus Verilog, gera matrizes pseudoaleatórias em Python com semente fixa, calcula C=A×B em Python e compara os 16 resultados completos com a simulação SystemVerilog.

## Limites técnicos
Este RTL é um protótipo funcional de arquitetura digital, não um chip físico. O Motorola é o host de desenvolvimento e simulação; não executa este RTL como circuito acelerador. Para obter hardware reconfigurável será necessário FPGA ou plataforma equivalente. Fabricação de silício exige um processo industrial ou serviço de fabricação.

A meta de 10× só poderá ser avaliada contra uma TPU específica, com mesmo modelo, precisão, batch, sequência, qualidade numérica e medição de latência/energia. A matriz 4×4 atual é uma etapa de pesquisa, não uma demonstração de superioridade sobre TPU.

## Roteiro
1. v0.1 — MAC INT8/INT32.
2. v0.2 — array 4×4, controlador GEMM e verificação Python/RTL.
3. v0.3 — encaminhamento PE-a-PE para fluxo sistólico clássico, interface de memória, tiling e métricas de tráfego.
4. v0.4 — escalas de quantização e formatos numéricos para treinamento.
5. v0.5 — gradientes, acumulação de gradientes e atualização de pesos.
6. Futuro — síntese FPGA, relatórios de temporização, área e potência.

## Status de verificação
Os arquivos de teste foram adicionados ao repositório. A aprovação efetiva da simulação Icarus deve ser confirmada executando `make all` no ambiente Ubuntu/Termux ou por CI. A aprovação de testes não comprova desempenho físico, frequência, consumo ou desempenho de TPU.
