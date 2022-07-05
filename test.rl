struct Language
    name  : String
end
struct Person
    name     : String
    age      : Number
    lang     : Language
end
person is Person("sty00a4", 17, Language("lua"))
return person.name + " is " + (person.age as String) + " ages old. He programs in " + person.lang.name + "."