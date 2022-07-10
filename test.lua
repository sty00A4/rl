os.clock()
local rl = require "rl"
local tokens, ast, value, vars, returning, err
local detail = false
local text = io.open("test.rl", "r"):read("*a")
tokens, err = rl.lex("test.rl", text) if err then print(err) return end
local lexTime = os.clock()
--if #tokens > 0 then for _, t in ipairs(tokens) do io.write(tostring(t)," ") end print("\n") end
ast, err = rl.parse(tokens) if err then print(err) return end
local parseTime = os.clock()
--print(rl.ast2str(rl.ast2str, ast))
value, returning, err = rl.interpret(ast) if err then print(err) return end
local runTime = os.clock()
if value ~= nil then print(value) end
print("\nfinished in "..tostring(math.floor((lexTime+parseTime+runTime)*1000)).."ms")
if detail then
    print("(lex: "..tostring(lexTime).."s, parse: "..tostring(parseTime).."s, run: "..tostring(runTime).."s)")
end