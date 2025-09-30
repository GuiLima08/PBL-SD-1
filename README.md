# Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog  

## 1. Introdução  
Este repositório apresenta a primeira etapa do projeto **"Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog"**, referente ao **Problema 1** do componente curricular **Sistemas Digitais** do semestre **2025.2**.  

O problema consiste na construção de um **coprocessador gráfico** para sistemas de vigilância e exibição em tempo real. O processamento é executado diretamente na **FPGA** da placa fornecida, modelo **DE1-SoC**.  

---

## 2. Requisitos  

- O código deve ser escrito em **Verilog**.  
- Devem ser implementados os seguintes algoritmos de redimensionamento de imagens:  
  - **Vizinho Mais Próximo (Nearest Neighbor Interpolation)**  
  - **Replicação de Pixel (Pixel Replication)**  
  - **Decimação / Amostragem (Nearest Neighbor for Zoom Out)**  
  - **Média de Blocos (Block Averaging)**  
- As imagens são representadas em **escala de cinza** e cada **pixel** é representado por um número inteiro de **8 bits**.  
- Devem ser utilizadas **chaves e/ou botões** para determinar a ampliação e redução da imagem.  
- O coprocessador deve ser **compatível com o processador ARM (HPS - Hard Processor System)** para viabilizar o desenvolvimento das próximas etapas.  

---

## 3. Detalhamento do Software  

| Categoria                        | Software              | Versão          | Função no Projeto                             |
|----------------------------------|-----------------------|-----------------|-----------------------------------------------|
| Ambiente de Desenvolvimento FPGA | Intel Quartus Prime   | 23.1 Lite Edition | Criação dos módulos e programação da FPGA.    |
| Simulação                        | Icarus Verilog        | v11-20210204    | Simulação dos algoritmos na memória           |
| Linguagem HDL                    | Verilog               | Verilog 2001    | Implementação do código do coprocessador.     |

---

## 4. Especificação dos Hardwares Usados nos Testes  

- **Placa de Desenvolvimento**: Kit **DE1-SoC (Cyclone V SE 5CSEMA5F31C6)**  

### Interfaces de Entrada Utilizadas  
- **Chaves**: Seleção do algoritmo e fator de ampliação/redução.  
- **Botões**: Aplicar o redimensionamento e redefinir (reset) o sistema.  

### Interface de Saída Utilizada  
- **VGA**: Exibição da imagem processada.  

### Periféricos Adicionais  
- **Monitor 640x480** com entrada VGA.  
