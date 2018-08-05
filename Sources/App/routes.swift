import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("hello", String.parameter) { req -> String in
        let name = try req.parameters.next(String.self)
        return "Hello \(name)"
    }
    
    // MARK: - Acronyms
    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).all()
    }
    
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }
    
    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self) .flatMap(to: Acronym.self) { arconym in
            return arconym.save(on: req)
        }
    }
    
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updateAcronym in
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            return acronym.save(on: req)
        }
    }
    
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }
}
