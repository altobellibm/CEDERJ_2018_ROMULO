from __future__ import print_function

import pandas as pd
import numpy as np
import tensorflow as tf
import time
import sys


# ler arquivo no formato fornecido pelo site:
def getMatrix(file):
    base = []
    items = {}

    dist = np.array(pd.read_csv(file, header=None, delim_whitespace=True))

    for ix, iy in np.ndindex(dist.shape):
        items[dist[ix, iy]] = items.get(dist[ix, iy], 0) + 1;

    l = list(items.keys())
    l.sort()

    # dicionario dos itens para index da matriz
    mapeamento = {}
    count = 0
    for item in l:
        mapeamento[item] = count
        count = count + 1

    # se arquivo estiver vazio.
    if not dist.size:
        print("Arquivo Vazio!")
        return None, None

    # verifica se existe um item de contexto, ou seja, item que tem 100% de frequencia na base.
    if max(list(items.values())) == dist.shape[0]:
        print("Base nao cumpre requisito, existe elementos de contexto, ou seja elementos que tem frequencia 100%")
        return None, None

    # matriz F de (0, 1)
    F = np.zeros((dist.shape[0],len(items)))
    for ix, iy in np.ndindex(dist.shape):
        F[ix, mapeamento[dist[ix, iy]]] = 1

    return F, dist.shape[1], dist.shape[0], len(items)

# obter nome arquivo
file = str(sys.argv[1])

if not file.endswith('.txt'):
    print("Arquivo nao pode ser lido!")

timeFile = file[:-4]
with open(timeFile + "_tempoProcessamentoGPU.txt", 'w') as f:
    start = time.time()
    Fo, q, n, m = getMatrix(file)
    end = time.time()

    f.write("Nome arquivo: " + file + "\n")
    f.write("Matriz formato = [" + str(n) + "," + str(m) + "]\n")
    f.write("Tempo criar matriz entrada (s): " + str(end - start) + "\n")

    start = time.time()
    #salvar a matriz resultande calculada na GPU
    resultado = []

    with tf.device("/gpu:0"):
        # Matriz F : matriz de entrada
        F = tf.convert_to_tensor(Fo, dtype=tf.float32)

        # matriz transposta de F
        Ft = tf.matrix_transpose(F)

        # vetor de frequencia de linha de F - Equacao (1)
        fr = tf.reduce_sum(F,1)

        # matriz diagonal formada em sua diagonal principal pelo vetor fr - Equacao (3)
        Dr = tf.diag(fr)

        # matriz inversa de Dr
        Dr_inverse = tf.matrix_inverse(Dr)

        # mutiplicacao de matrizes
        A = tf.matmul(Ft,Dr_inverse)

        # mutiplicacao de matrizes
        B = tf.matmul(A,F)

        # vetor de frequencia de colunas F - Equacao (2)
        fc = tf.reduce_sum(F,0)

        # matriz diagonal formada em sua diagonal principal pelo vetor fc - Equacao (4)
        Dc = tf.diag(fc)

        # matriz inversa de Dc
        Dc_inverse = tf.matrix_inverse(Dc)

        # matriz  quadrada M - Equacao (5)
        M = tf.matmul(B,Dc_inverse)

        # Sendo D o vetor de autovalores e X a matriz de autovetores produzidos pela funcao
        D, X = tf.self_adjoint_eig(M)
        #, usa-se a funcao REVERSE para ordenar de forma decrescente
        # os valores dos autovalores e dos autovetores. Da seguinte maneira:
        er = tf.reverse(D, axis=[0])
        Vr = tf.reverse(X, axis=[0])

        e = tf.slice(er,[1],[q])
        V = tf.slice(Vr,[0,1],[m, q])

        # matriz com todos os elementos de V elevados ao quadrado
        H = tf.multiply(V,V)

        # multipicacao de matrizes - Equacao (7)
        T = tf.matmul(Dc,H)

        # vetor de frequencia de T - Equacao (8)
        tc = tf.reduce_sum(T,0)

        # somatorio de todos valores da matriz F - Equacao (9)
        ft = tf.reduce_sum(F)

        # divisao de ft por tc
        G = tf.div(ft,tc)

        # vetor - Equacao (10)
        Cc = tf.sqrt(G)

        # vetor que contem os mutiplicadores para as colunas da matriz de peso padrao N - Equacao (11)
        Rho = tf.sqrt(e)

        # matriz de peso padrao - Equacao (12)
        N = tf.multiply(V, Cc)

        # matriz de peso projetado - Equacao (13 )
        P = tf.multiply(N,Rho)

    #sess = tf.Session(config=tf.ConfigProto(log_device_placement=True))
    #print('\n Matriz Dc \n' ,sess.run(P))
    

    with tf.Session(config=tf.ConfigProto(log_device_placement=True)) as session:
        resultado.append(session.run(P))
    
    #sess = tf.Session()
    #with sess.as_default():
    #    tensor = tf.range(10)
    #    print_op = tf.print(tensor)
    #    with tf.control_dependencies([print_op]):
    #        out = tf.add(tensor, tensor)
    #    sess.run(out)
    #print('\n Matriz Dc \n' ,sess.run(P))

  
        
    end = time.time()

    f.write("Tempo calcular em GPU (s): " + str(end - start) + "\n")