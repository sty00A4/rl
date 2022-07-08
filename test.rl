struct Language
    name  : String
end
struct Person
    name     : String
    age      : Number
    lang     : Language
    func introduce(self, lang:Bool is false) -> String
        string is "I'm " + self.name + " and " + (self.age as String) + " years old."
        # include lang if asked for
        if (lang) string is string + " I program in " + self.lang.name + "." end
        # change age each introduction
        inc self.age
        return string
    end
end
person is Person("sty00a4", 17, Language("lua"))
for 1 to 10
    # print lang on every even age
    print(person.introduce())
end
