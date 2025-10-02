# Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog  

## Equipe

- **[Davi Medeiros Rocha](https://github.com/Davi-UEFS)**

- **[Guilherme de Oliveira Lima](https://github.com/GuiLima08)**

- **[Nycolas de Lima Oliveira Silva](https://github.com/NycolasDeLima)**


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
| Ambiente de Desenvolvimento FPGA | Intel Quartus Prime   | 23.1 Lite Edition | Criação dos módulos e programação da FPGA.  |
| Biblioteca de módulos            | Quartus IP Catalog    | 23.1 Lite Edition | Importação dos módulos preexistentes (RAM, PLL) |
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

## 5. Arquitetura

O projeto elaborado possui módulos escritos em linguagem verilog que interagem entre si para realizar o processo de redimensionamento e exibição de uma imagem de resolução 160x120. A arquitetura é composta dos seguintes principais módulos: RAM Initial, RAM Final, Coprocessor, PLL 100 MHz e VGA Driver. Todos esses módulos são englobados pelo módulo Top-Level responsável pelas entradas/saídas e comunicação entre os módulos.

<img width="556" height="381" alt="Michael_Rosoft drawio" src="https://github.com/user-attachments/assets/efa204d1-8ed0-4a62-8401-023e9e526e2e" />

As entradas são realizadas por meio das chaves e botôes da placa. As sáidas são mandadas para um monitor com entrada VGA.

| **Entradas** | **Saídas** |
|---|---|
|Clock de 50MHz | Red, Green, Blue (8 bits) |
| Botão de Reset | Hsync, Vsync |
| Seleção do algoritmo (3 bits) | Blank |
| Seleção do fator de zoom (2 bits) | Sync |
| Botão de Start | Clock de 25MHz |

A seleção de algoritmo é um Opcode que determina o tipo de algoritmo a ser aplicado na imagem.

| **OPCODE** | **ALGORITMO** |
|---|---|
| **000** | Média de Blocos |
| **001** | Vizinho mais próximo |
| **010** | Decimação / Amostragem |
| **011** | Replicação de Pixel |
| **1XX** | Imagem Original|

A seleção de fator determina qual o fator do redimensionamento aplicado na imagem.

| **OPCODE** | **FATOR** |
|---|---|
| **00** | 2x |
| **01** | 4x |
| **10** | 8x (zoom out) / 4x(zoom in) |
| **11** | 2x |

### PLL 100 MHz
O PLL é responsável por converter o clock natural da placa de 50 MHz em um clock de 100 MHz. Como a RAM utilizada é do tipo M10k, é necessário uma frequência de no mínimo 75 MHz para que o atraso de leitura da RAM seja de 1 ciclo. O atraso de RAM adotado para o projeto foi de 1 ciclo e a frequência utilizada foi de 100 MHz para as memórias.

### RAM Initial
Armazena a imagem original. Fornece dados da imagem original ao coprocessador. Está sempre em modo de leitura.

### RAM Final
Armazena a imagem processada pelo coprocessador. Fornece dados da imagem a ser exibida para o VGA Driver. O endereço de leitura do VGA Driver e o endereço de escrita do coprocessador são multiplexados pelo Top-Level para que não haja tentativa de leitura da memória antes do término da escrita da imagem processada. O modo de escrita é habilitado e desabilitado pelo coprocessador.

### VGA Driver
Lê a memória RAM Final para exibir a imagem processada. A imagem será mostrada em escala de cinza. Realiza a varredura do monitor e informa as coordenadas do próximo pixel a ser exibido. Informação usada para calcular o endereço de leitura da RAM Final.

### Logic
Bloco de lógica e aritmética responsável por calcular o endereço de leitura do VGA Driver e multiplexa-lo com o endereço de escrita vindo do coprocessador para que resulte no endereço que será entrada na RAM Final. O sinal de controle do multiplexador é o frame pronto vindo do coprocessador.

### Coprocessor
Coprocessador responsável pelo processamento da imagem. Lê a imagem original na RAM Initial e escreve o resultado do processamento na RAM Final. É composto por dois módulos: Unidade de Controle (UC) e Unidade Lógica e Aritmética (ULA).

### Unidade de Controle (UC)
A UC é uma máquina de estados finitos que coordena o funcionamento do coprocessador. O gerenciamento da UC garante que a ULA realize o processamento na ordem correta e que os sinais de controle sejam gerados no momento adequado. Uma de suas saídas é a de frame pronto. O frame pronto serve para indicar que o processamento da imagem foi finalizado.


<img width="1920" height="1080" alt="Zoom Digital Redimensionamento de Imagens com FPGA em Verilog" src="https://github.com/user-attachments/assets/6980ea8a-8414-4ff3-a240-254db5b8cdc9" />



| **Estado**| |
|---|---|
| **IDLE** | Aguarda sinal de aplicação de redimensionamento vindo do botão Start. |
| **RUN** | Inicializa a ULA. Quando o processamento termina, ativa o sinal de frame pronto. |
| **DONE** | Mantém o sinal de frame pronto até receber um novo sinal de aplicação de redimensionamento. |
| **PREPARE**| Atraso de 1 ciclo de clock antes de voltar para RUN. |

### Unidade Lógica e Aritmética (ULA)
A ULA desempenha o papel de aplicar os algoritmos sobre a imagem. Calcula os endereços de leitura na RAM Initial e de escrita na RAM Final. Fornece o sinal de ativação de escrita na memória. Os algoritmos são aplicados por meio de uma máquina de estados finitos.


<img width="1920" height="1080" alt="Zoom Digital Redimensionamento de Imagens com FPGA em Verilog(1)" src="https://github.com/user-attachments/assets/fc846ef5-34b3-4981-ae41-dcce9af45b34" />


| **Estado**| |
|---|---|
| **IDLE** | Aguarda  o sinal de inicialização da UC. |
| **FETCH** | Cálculo do endereço de leitura do pixel na imagem original. |
| **WAIT FETCH** | Aguarda a leitura da memória. |
| **PREPARATION** | Cálculo do valor do pixel a ser escrito na memória. Caso o algoritmo aplicado seja a média de blocos, há retorno para o estado de fetch para ler os demais pixels para realização da média. |
| **CALC ADDRESS** | Cálculo do endereço de escrita do pixel. |
| **WRITE** | Habilita sinal de escrita da memória. |
| **NEXT** | Incrementa os registradores para o cálculo do próximo endereço de leitura. Caso o algoritmo aplicado seja a replicação de pixel, não há necessidade de ler outro pixel da memória enquanto o lido estiver sendo replicado, por isso há retorno para o estado de CALC ADDRESS. Enquanto a imagem não tiver sido completamente processada, haverá retorno para o estado de FETCH. |
| **DONE** | Sinaliza que a ULA terminou o processamento. | 



---

## 6. Testes

Os algoritmos de **vizinho mais próximo, replicação de pixel, decimação** e **média de blocos** foram testados utilizando a ferramenta **Icarus Verilog**, um simulador de hardware de código aberto que compila e executa projetos descritos em linguagem Verilog. Os códigos para testes no Icarus Verilog (encontrados na pasta *PBL-SD-1/Testes_Algoritmos* dentro do repositório) utilizaram matrizes pequenas para testar os algoritmos, e foram subsequentemente adaptados para matrizes de larga escala e implementados no projeto.

Durante a implementação dos algoritmos em conjunção com o módulo do VGA, os testes foram feitos de forma prática na placa DE1-SoC, juntamente com um monitor VGA. Foi produzida uma imagem específica para testes de sincronismo:

![checker160.jpg](https://github.com/user-attachments/assets/c716bad4-4e0b-4010-95a3-c0e52d8585f7)

A imagem acima possui ângulos retos e quadrados perfeitos, utilizados para melhor visualizar erros de sincronismo e *offset*. A área cinza nos lado esquerdo e superior da imagem serve para verificar se a imagem possui duplicação de linhas ou colunas de pixel.

---

## 7. Análise dos Resultados

![pixelreplication](https://github.com/user-attachments/assets/6c6866b7-51a6-47a6-a530-b663807d49c4)
*Aplicação do algoritmo de Replicação de Pixel*

![nnzoomout](https://github.com/user-attachments/assets/f99f99f1-aa6f-4ff3-8c3e-1bedeee66b11)
*Aplicação do algoritmo de Zoom Out com Vizinho Mais Próximo*

![nnzoomin](https://github.com/user-attachments/assets/b49bacd0-3690-4f3a-8ed6-cbff3d2e2755)
*Aplicação do algoritmo de Zoom In com Vizinho Mais Próximo*

![blockaverage](https://github.com/user-attachments/assets/6ae147f9-5f01-4fc4-943e-585f32ef90c9)
*Aplicação do algoritmo de Média de Blocos*

Em análise do produto obtido nesta etapa do desenvolvimento, pode-se afirmar que os requisitos do problema foram implementados. Todos os algoritmos foram implementados, controlados pelo usuário através das chaves e botões da placa, como foi pedido. Um erro observado durante o desenvolvimento foram *“estrias”* minúsculas de coloração vermelha na imagem; tal erro foi solucionado ao alterar a lógica do cálculo do *offset* da imagem, fazendo a verificação e correção de valores inválidos.

| Requisito | Resultado |
|---|---|
| Código escrito em Verilog | Cumprido |
| Implementar os 4 algoritmos de zoom-in e zoom-out | Cumprido |
| Imagens em escala de cinza | Cumprido |
| Controle do zoom através de chaves e botões | Cumprido |

Em uma análise do processo de desenvolvimento e aprendizado decorrido durante a etapa do PBL, pode-se dizer que os desafios iniciais do problema, e suas subsequentes soluções, culminaram em uma forte e consolidada base de aprendizado, gerando melhor entendimento sobre a estrutura de um coprocessador e elaboração de circuitos verilog, assim como o incentivo de encontrar uma abordagem prática e eficiente para problemas relacionados ao campo de sistemas digitais. O maior desafio encontrado, porém, seria a implementação do sincronismo entre os componentes do sistema, o que gerou diversos obstáculos durante esta etapa; problemas estes que foram corrigidos com sucesso.

## 8. Observações
- O código acompanha dois arquivos .mif para teste: "gatinho2_convertido" e "checker160". Para mudar, deve-se alterar o caminho no módulo "ram_initial.v".
- Similarmente, caso os módulos da RAM não forem instanciados corretamente, eles podem ser criados novamente usando a função RAM 1-PORT do IP Catalog. Note que eles devem ter o mesmo nome, largura e profundidade dos disponibilizados no repositório.

## 9. Bibliografia
- Manual DE1-SoC <http://www.ee.ic.ac.uk/pcheung/teaching/ee2_digital/de1-soc_user_manual.pdf>
- Módulo VGA Driver. Adams, V. Hunter <https://vanhunteradams.com/DE1/VGA_Driver/Driver.html> 
