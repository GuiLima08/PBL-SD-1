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

## 5. (nycolas coloca tua parte aq)



---

## 6. Testes

Os algoritmos de **vizinho mais próximo, replicação de pixel, decimação** e **média de blocos** foram testados utilizando a ferramenta **Icarus Verilog**, um simulador de hardware de código aberto que compila e executa projetos descritos em linguagem Verilog. Os códigos para testes no Icarus Verilog (encontrados na pasta *PBL-SD-1/Testes_Algoritmos* dentro do repositório) utilizaram matrizes pequenas para testar os algoritmos, e foram subsequentemente adaptados para matrizes de larga escala e implementados no projeto.

Durante a implementação dos algoritmos em conjunção com o módulo do VGA, os testes foram feitos de forma prática na placa DE1-SoC, juntamente com um monitor VGA. Foi produzida uma imagem específica para testes de sincronismo:

![checker160.jpg](https://github.com/user-attachments/assets/c716bad4-4e0b-4010-95a3-c0e52d8585f7)

A imagem acima possui ângulos retos e quadrados perfeitos, utilizados para melhor visualizar erros de sincronismo e *offset*. A área cinza nos lado esquerdo e superior da imagem serve para verificar se a imagem possui duplicação de linhas ou colunas de pixel.

---

## 7. Análise dos Resultados

Em análise do produto obtido nesta etapa do desenvolvimento, pode-se afirmar que os requisitos do problema foram implementados. Todos os algoritmos foram implementados, controlados pelo usuário através das chaves e botões da placa, como foi pedido. Um erro observado, porém, foram *“estrias”* minúsculas de coloração vermelha na imagem, provavelmente um produto de algum erro no sincronismo entre a RAM e o VGA. Tal erro deve ser corrigido na segunda etapa do desenvolvimento.

| Requisito | Resultado |
|---|---|
| Código escrito em Verilog | Cumprido |
| Implementar os 4 algoritmos de zoom-in e zoom-out | Cumprido |
| Imagens em escala de cinza | Parcialmente cumprido (estrias vermelhas foram encontradas) |
| Controle do zoom através de chaves e botões | Cumprido |

Em uma análise do processo de desenvolvimento e aprendizado decorrido durante a etapa do PBL, pode-se dizer que os desafios iniciais do problema, e suas subsequentes soluções, culminaram em uma forte e consolidada base de aprendizado, gerando melhor entendimento sobre a estrutura de um coprocessador e elaboração de circuitos verilog, assim como o incentivo de encontrar uma abordagem prática e eficiente para problemas relacionados ao campo de sistemas digitais. O maior desafio encontrado, porém, seria a implementação do sincronismo entre os componentes do sistema; fato evidenciado pelo erro discutido no parágrafo anterior.

## 8. Observações
- O código acompanha dois arquivos .mif para teste: "gatinho2_convertido" e "checker160". Para mudar, deve-se alterar o caminho no módulo "ram_initial.v".
- Similarmente, caso os módulos da RAM não forem instanciados corretamente, eles podem ser criados novamente usando a função RAM 1-PORT do IP Catalog. Note que eles devem ter o mesmo nome, largura e profundidade dos disponibilizados no repositório.
