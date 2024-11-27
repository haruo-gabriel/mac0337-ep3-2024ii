-- seleciona o vetor correspondente ao argumento
local v = "$0B_"..a
local x = ofArray(v)
local N = x:getSize()

-- acessa identificadores de [send]'s no patch para enviar as respostas
local sendpico = ofSend(v.."_pico")
local sendampmed = ofSend(v.."_ampmed")
local sendamprms = ofSend(v.."_amprms")
local sendenergia = ofSend(v.."_energia")
local sendenergiadb = ofSend(v.."_energiadb")

-- calcula máximo, soma e soma dos quadrados dos valores absolutos no vetor
local pico = 0
local ampmed = 0
local energia = 0

for i = 0, N-1 do
    pico = math.max(pico, math.abs(x[i]))
    ampmed = ampmed+math.abs(x[i])
    energia = energia+x[i]*x[i]
end

-- envia respostas para o patch
sendpico:sendFloat(pico)
sendampmed:sendFloat(ampmed/N)
sendamprms:sendFloat(math.sqrt(energia/N))
sendenergia:sendFloat(energia/N)
sendenergiadb:sendFloat(10*math.log(energia/N)/math.log(10))
