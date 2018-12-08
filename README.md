
# CEDERJ_2018_ROMULO


USO DA BIBLIOTECA CUSP EM CUDA PARA IMPLEMENTAÇÃO DO ALGORITMO DUAL SCALING EM DADOS CATEGÓRICOS MULTIVARIADOS

Trabalho de Conclusão de Curso submetido ao Curso de Tecnologia em Sistemas de Computação da Universidade Federal 
Fluminense como requisito parcial para obtenção do título de Tecnólogo em Sistemas de Computação.

Para atender esse cenário que vivemos em relação ao crescimento da geração de informações, a busca por ferramentas que 
consigam aumentar seu poder de processamento, de modo a acompanhar esse crescimento do volume de dados, é algo 
constante. Para atender essa necessidade, são desenvolvidas diversas técnicas de extração de informações úteis de modo que 
se a eficiência do processamento destas técnicas seja máxima. O Dual scaling tem com o objetivo gerar uma contextualização 
espacial através da correlação de itens de uma base de dados com a apresentação dos resultados de forma simples, intuitiva 
e precisa. Porém esta técnica possui um modelo matemático para a geração dos resultados altamente custoso e, atualmente, 
somente soluções implementadas de forma sequencial são disponibilizadas no mercado. Neste trabalho, é implementado o 
algoritmo de Dual scaling paralelizável através da utilização dos processadores em uma GPU com o auxílio da biblioteca 
Cusp para facilitar a implementação. Posteriormente são feitos testes de tempo de execução com duas implementações de 
forma sequencial a fim de validar a implementação proposta. Por fim, algumas ideias para trabalhos futuros são apresentadas 
para dar continuidade a este estudo.



## Bibliotecas

* [Cusp](https://cusplibrary.github.io/)
* [Tensorflow](https://www.tensorflow.org/install/)
* [Eigen](http://eigen.tuxfamily.org/index.php?title=Main_Page)



## Compiladores

* [nvcc](https://developer.nvidia.com/cuda-toolkit)
* [g++](https://gcc.gnu.org/)
* [python](https://www.python.org/downloads/)
