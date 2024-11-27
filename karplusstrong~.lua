-- Variáveis locais
local tabelaKS = ofTable()
local L = 0
local R = ofGetSampleRate()
local indice_tabela = 1
local indice_fadeout = 1
local duracao_amostras = 0 
local amostras_processadas = 0

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
  indice_fadeout = 1
  indice_tabela = 1
  amostras_processadas = 0

  local F = lista[1]
  print('F: ' .. F)
  local D = lista[2]
  print('D: ' .. D)
  L = math.floor(R/F)
  print('L: ' .. L)

  -- Define duracao_amostras
  duracao_amostras = math.floor(D*R + 0.5)

  -- Inicializa tabelaKS
  for i=1, L do
    tabelaKS[i] = 2*math.random()-1
  end

  -- Subtrai cada elemento da tabelaKS pela média
  local media = mediaTabela(L)
  for i=1, L do
    tabelaKS[i] = tabelaKS[i] - media
  end

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
  -- Varre 1 bloco de 64 amostras
  for i=1, 64 do
    bloco[i] = tabelaKS[indice_tabela]

    -- Processa fade-out
    if amostras_processadas > (duracao_amostras - 10) then
      bloco[i] = bloco[i] * (1 - indice_fadeout/10)
      if indice_fadeout < 10 then
        indice_fadeout = indice_fadeout + 1
      end
    end

    -- Incrementa índices
    indice_tabela = (indice_tabela % L) + 1
    amostras_processadas = amostras_processadas + 1
  end

  return bloco
end