struct Person
    name : String
    age  : Number
end
person is Person("sty00a4", 17)
debugMem()
return person.name + " is " + (person.age as String) + " ages old."