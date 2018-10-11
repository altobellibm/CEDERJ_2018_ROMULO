#pragma once

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <map>
#include <algorithm>

#include <cusp/coo_matrix.h>


using namespace std;

class BASE_NUM{
        friend class LeitorBaseNumerico;
private:
    map<int, int> 		m_cabecalho;
    map<int, int> 		m_cabecalhoIdReal;
    vector<vector<int>> 	m_transacoes;
    int 			numberOfOnes;
    
public:
    BASE_NUM(){}

        //Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic> getMatrix(){
    
        cusp::coo_matrix<int, float, cusp::device_memory> getMatrix(){
    
        if (m_transacoes.empty()){
            cusp::coo_matrix<int, float, cusp::device_memory> A(0,0,0);
            return A;
        }

        int subjects = m_transacoes.size();
        int stimuli = m_cabecalho.size();
        int nonzeros = numberOfOnes;
        
   /*     
        cout<<"m_transacoes"<<endl;
        for ( std::vector<std::vector<int>>::size_type i = 0; i < m_transacoes.size(); i++ ){
            for ( std::vector<int>::size_type j = 0; j < m_transacoes[i].size(); j++ ){
                std::cout << m_transacoes[i][j] << ' ';
            }
        std::cout << std::endl;
        }
        
        cout<<"\n m_cabecalho"<<endl;
        for(auto elem : m_cabecalho){
            std::cout << elem.first << " " << elem.second << "\n";
           }
    */    
        cusp::coo_matrix<int, float, cusp::device_memory> sparse_matrix(subjects,stimuli,nonzeros);

        int i = 0;
        int j = 0;
        for (auto transation : m_transacoes){
            for (auto item : transation){
                sparse_matrix.row_indices[j] = i; 
                sparse_matrix.column_indices[j] = m_cabecalho[item];
                sparse_matrix.values[j] = 1;
                //dynamic_size_matrix(i, m_cabecalho[item]) = 1;
                j++;
            }
        i++;
        }

        return sparse_matrix;
    }

    unsigned int getSizeTransation() const { return m_transacoes.size();}

    vector<vector<int>>	getTransation() const {return m_transacoes;}

    map<int, int>  getCabecalho() const {return m_cabecalho;}
    map<int, int>  getCabecalhoIdReal() const {return m_cabecalhoIdReal;}





};

class LeitorBaseNumerico
{
public:
    LeitorBaseNumerico() {}

    static bool obterDadoArquivo(const std::string& _strArquivo, BASE_NUM& _dado){
        std::ifstream myfile(_strArquivo);

        if (! myfile.is_open()) {
            std::cout << "Nao abriu o arquivo!" << std::endl;
            return false;
        }

        map<int, int> frequenceId;
        std::string line;
	_dado.numberOfOnes = 0;
        while (getline(myfile, line)){
            auto transation = splitInt(line);
            _dado.numberOfOnes = _dado.numberOfOnes + transation.size();
            _dado.m_transacoes.push_back(transation);

            for(auto id: transation)
                frequenceId[id]++;
        }
	
        myfile.close();
        
        //arquivo sem transaçoes
        if (_dado.m_transacoes.size() == 0){
            cout << "Arquivo vazio!" << endl;
            return false;
        }
        
        if(context(frequenceId, _dado.m_transacoes.size())){
            cout << "Base não cumpre requisito, existe elementos de contexto, ou seja elementos que tem frequência 100%" << endl;
            return false;
        }

        int indexMatrix = 0;
        for(auto pair : frequenceId){
            _dado.m_cabecalho[pair.first] = indexMatrix;
            _dado.m_cabecalhoIdReal[indexMatrix] = pair.first;
            indexMatrix++;
        }

        return true;
    }

private:

    static bool context(const map<int, int>& _frequenceId ,int _tamBase){
        for(auto pair : _frequenceId)
            if(pair.second == _tamBase)
                return true;
        return false;
    }

    static vector<string> split( string s, char c = ' '){
        vector<string> v;

        istringstream iss(s);
        string token;
        
        while (getline(iss, token, c))
            v.push_back(token);

        return v;
    }

    static vector<int> splitInt( string s, char c = ' '){
        vector<int> v;
        vector<string> resul = split(s,c);

        for(auto item : resul)
            v.push_back(atoi(item.c_str()));
        
        return v;
    }
};
