-- Variáveis locais
local tabelaKS = ofTable()
-- Tabelas auxiliares
local tabelaKS_antes = ofTable()
local tabelaKS_depois = ofTable()
--
local R = ofGetSampleRate()
local L = 0

local indice_tabela = 1
local amostras_processadas_fadeout = 0
local duracao_em_amostras
local amostras_processadas = 0


-- Função auxiliar para calcular a média de uma lista
function mediaTabela(n_amostras)
  local soma = 0
  for i=1, n_amostras do
    soma = soma + tabelaKS[i]
  end
  return soma / n_amostras
end

-- Processa a lista de entrada
function ofelia.list(lista)
  -- Inicializa variáveis
  amostras_processadas_fadeout = 1
  indice_tabela = 1
  amostras_processadas = 0

  local F = lista[1]
  print('F: ' .. F)
  local D = lista[2]
  print('D: ' .. D)
  L = math.floor(R/F)
  print('L: ' .. L)

  duracao_em_amostras = math.floor(D*R + 0.5)

  -- Inicializa tabelaKS
  for i=1, L do
    tabelaKS[i] = 2*math.random()-1
  end
  local media = mediaTabela(L)
  for i=1, L do
    tabelaKS[i] = tabelaKS[i] - media
  end


  -- Preenche as tabelas auxiliares
  -- for i=1, L do
  --   tabelaKS_antes[i] = tabelaKS[i]
  -- end
  -- for i=1, L do
  --   tabelaKS_depois = 0.5 * (tabelaKS[i] + tabelaKS[(i-2)%L+1])
  -- end

  -- Imprime tabelaKS em 1 linha
  local tabelaKS_str = {}
  for i=1, L do
    tabelaKS_str[i] = tostring(tabelaKS[i])
  end
  print("Tabela KS: " .. table.concat(tabelaKS_str, ", "))

  -- Imprime tabelaKS em várias linhas
  -- print("tabelaKS: ")
  -- for i=1, L do
  --   print(tabelaKS[i])
  -- end
end



function ofelia.perform(bloco)
  -- Preenche o bloco de 64 amostras
  for i=1, 64 do
    bloco[i] = tabelaKS[indice_tabela]

    -- Processa fade-out
    if amostras_processadas > (duracao_em_amostras - 10) then
      if amostras_processadas_fadeout < 10 then
        bloco[i] = bloco[i] * (1 - amostras_processadas_fadeout/10)
        amostras_processadas_fadeout = amostras_processadas_fadeout + 1
      else
        bloco[i] = 0
      end
    end

    -- Atualiza tabelaKS com média móvel
    tabelaKS[indice_tabela] = 0.5 * (tabelaKS[indice_tabela] + tabelaKS[(indice_tabela-2)%L+1])

    -- Incrementa índices globais
    indice_tabela = (indice_tabela % L) + 1
    amostras_processadas = amostras_processadas + 1
  end

  -- -- Atualiza as tabelas KS
  -- for i=1, 64 do
  --   tabelaKS_depois[indice_tabela] = 0.5 * (tabelaKS[indice_tabela] + tabelaKS[(indice_tabela-2)%L+1])
  -- end

  return bloco
end