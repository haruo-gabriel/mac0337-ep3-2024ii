-- Variáveis locais
local tabelaKS = ofTable()
local R = ofGetSampleRate()
local F = 0
local D = 0
local L = 0
local A = 0
local ind_tab = 1 -- índice da tabela KS
local dur_am      -- duração em amostras
local am_proc = 0 -- amostras processadas
local enc = 1     -- parâmetro de encurtamento [0, 1]
local prol = 0.5  -- parâmetro de prolongamento [0, 0.5]


-- Função auxiliar para calcular a média de uma lista
function mediaTabela(n_amostras)
  local soma = 0
  for i=1, n_amostras do
    soma = soma + tabelaKS[i]
  end
  return soma / n_amostras
end

-- Função auxiliar para calcular parâmetros de encurtamento
-- e prolongamento da função de filtro
function calcula_enc_pro(F, D, R)
  local g0 = math.cos(math.pi*F/R)
  local g1 = 10^(-3/(F*D))

  if g0 >= g1 then
    enc = g1 / g0
    prol = 0.5
  else
    enc = 1
    local numerador = 4*(1-g1^2)
    local denominador = 2 - 2*math.cos(2*math.pi*F/R)
    prol = 0.5 - 0.5*(math.sqrt(1 - numerador/denominador))
  end
end

-- Processa a lista de entrada
function ofelia.list(lista)
  -- Inicializa variáveis
  ind_tab = 1
  am_proc = 0

  F = lista[1]
  print('F: ' .. F)
  D = lista[2]
  print('D: ' .. D)
  A = lista[3]
  print('A: ' .. A)

  dur_am = math.floor(D*R + 0.5)

  calcula_enc_pro(F, D, R)

  L = math.floor(R/F - prol)

  -- Inicializa tabelaKS
  for i=1, L do
    tabelaKS[i] = 2*math.random()-1
  end
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
  print("")
end

function passa_baixa()
  local tabelaKS_filtrada = ofTable()
  for i=1, L do
    tabelaKS_filtrada[i] = enc * ((1-prol)*tabelaKS[i] + prol*tabelaKS[(i-2)%L+1])
  end
  for i=1, L do
    tabelaKS[i] = tabelaKS_filtrada[i]
  end
end

function ofelia.perform(bloco)
  -- Preenche o bloco de 64 amostras
  for i=1, 64 do
    if (am_proc < A*L) or (am_proc > dur_am) then
      -- Processa pós-fadeout & ataque
      bloco[i] = 0
    elseif am_proc > (dur_am - 10) then
      -- Processa fadeout
      bloco[i] = bloco[i] * (1 - (dur_am - am_proc)/10)
    else
      bloco[i] = tabelaKS[ind_tab]
    end

    -- Atualiza tabelaKS com passa-baixa
    if ind_tab == 1 then
      passa_baixa()
    end

    -- Incrementa índices globais
    ind_tab = (ind_tab % L) + 1
    am_proc = am_proc + 1
  end

  return bloco
end