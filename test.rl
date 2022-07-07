struct Language
    name  : String
end
struct Person
    name     : String
    age      : Number
    lang     : Language
end
func info(person:Person) -> String
    return person.name + " is " + (person.age as String) + " years old. He programs in " + person.lang.name + "."
end
person is Person("sty00a4", 17, Language("lua"))
return info("sty00a4")