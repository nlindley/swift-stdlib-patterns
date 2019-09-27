import Foundation

let imageEnd: String? = "Hello"
//let imageEnd: String? = nil

let imagePath
    = imageEnd != nil
        ? "https://examples.com/v1/Images?imagePath=\(imageEnd!)"
        : nil

//imagePath
let doubles = [1, 2, 3].map { $0 * 2 }

doubles

//let imagePath = imageEnd.map { "https://example.com/v1/Images?imagePath=\($0)" }

struct Person: Decodable {
    let name: String;
    let age: Int;
}

let wellFormed = """
{
    "name": "Pat",
    "age": 42
}
""".data(using: .utf8)!

let illFormed = """
[{
    "name": "Pat",
    "age": 42
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
let person = Result { try decoder.decode(Person.self, from: wellFormed) }

let age = person.map { $0.age }

switch age {
case .failure(let error):
    print(error)
case .success(let age):
    print(age)
}

struct JsonIpResponse: Decodable {
    let ip: String
}
let url = URL(string: "https://jsonip.com")!
let responseData = Result { try Data(contentsOf: url) }
func decodeJsonIp(_ data: Data) -> Result<JsonIpResponse, Error> {
    let ipDecoder = JSONDecoder()
    return Result { try ipDecoder.decode(JsonIpResponse.self, from: data) }
}
let jsonIpResult = responseData.flatMap(decodeJsonIp)
let ip = jsonIpResult.map { $0.ip }

let a: Set<Int> = [1, 2, 3]
