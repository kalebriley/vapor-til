import Vapor
import Fluent

// MARK: - REGISTRY
struct AcronymController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "acronyms")
        
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.get(Acronym.parameter, use: getHandler)
        acronymsRoute.get("search", use: searchHandler)
        acronymsRoute.get("sorted", use: sortHandler)
        
        acronymsRoute.put(Acronym.parameter, use: updateHandler)
        acronymsRoute.post(use: createHandler)
        acronymsRoute.delete(Acronym.parameter, use: deleteHandler)
        
    }
}

// MARK: CREATE - POST
extension AcronymController {
    func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
            return acronym.save(on: req)
        }
    }
}


// MARK: READ - GET
extension AcronymController {
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws ->  Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or)  { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }
    
    func sortHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
}

// MARK: UPDATE - PUT
extension AcronymController {
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) { acronym, updatedAcronym in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            return acronym.save(on: req)
        }
    }
}

// MARK: DELETE - DELETE
extension AcronymController {
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
}





