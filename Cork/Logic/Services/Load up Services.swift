//
//  Load up Services.swift
//  Cork
//
//  Created by David Bureš on 20.03.2024.
//

import Foundation
import CorkShared

enum HomebrewServiceLoadingError: LocalizedError
{
    case standardErrorNotEmpty(standardError: String), homebrewOutdated, standardErrorNotEmptyAndNoResultsInStandardOutput, couldNotEncodeString(String), servicesParsingFailed, otherError(String)

    var errorDescription: String?
    {
        switch self
        {
        case .standardErrorNotEmpty(let standardError):
            return String(localized: "error.services.loading.standard-error-not-empty.\(standardError)")
        case .standardErrorNotEmptyAndNoResultsInStandardOutput:
            return String(localized: "error.services.loading.no-output")
        case .couldNotEncodeString(let string):
            return String(localized: "error.services.loading.could-not-encode-string.\(string)")
        case .servicesParsingFailed:
            return String(localized: "error.services.loading.parsing-failed")
        case .otherError(let string):
            return String(localized: "error.services.loading.other-error.\(string)")
        case .homebrewOutdated:
            return String(localized: "error.services.loading.homebrew-outdated")
        }
    }
}

extension ServicesTracker
{
    fileprivate struct ServiceCommandOutput: Codable
    {
        /// Name of the service
        let name: String

        /// Current status of the service
        let status: ServiceStatus

        /// The executor user
        let user: String?

        /// Address of the service
        let file: URL

        /// Exit code of the service
        let exitCode: Int?
    }

    /// Load services into the service tracker
    func loadServices() async throws
    {
        let decoder: JSONDecoder = {
            let decoder: JSONDecoder = .init()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            return decoder
        }()

        let rawOutput: TerminalOutput = await shell(AppConstants.shared.brewExecutablePath, ["services", "list", "--json"])

        // MARK: - Error checking

        if !rawOutput.standardError.isEmpty
        {
            AppConstants.shared.logger.error("Failed while loading up services: Standard Error not empty")
            if rawOutput.standardError.contains("brew update")
            {
                throw HomebrewServiceLoadingError.homebrewOutdated
            }
            else
            {
                throw HomebrewServiceLoadingError.standardErrorNotEmpty(standardError: rawOutput.standardError)
            }
        }

        do
        {
            guard let decodableData: Data = rawOutput.standardOutput.data(using: .utf8, allowLossyConversion: false)
            else
            {
                AppConstants.shared.logger.error("Failed while converting services string to data")
                throw HomebrewServiceLoadingError.otherError("There was a failure encoding Services data")
            }

            /// Without this guard, the decoding throws, even if there was no error, just because the data is empty
            guard !decodableData.isEmpty else
            {
                return
            }
            
            let rawDecodedServicesData: [ServiceCommandOutput] = try decoder.decode([ServiceCommandOutput].self, from: decodableData)

            var finalServices: Set<HomebrewService> = .init()

            for decodedService in rawDecodedServicesData
            {
                finalServices.insert(.init(
                    name: decodedService.name,
                    status: decodedService.status,
                    user: decodedService.user,
                    location: decodedService.file,
                    exitCode: decodedService.exitCode
                ))
            }

            services = finalServices
        }
        catch let servicesParsingError
        {
            AppConstants.shared.logger.error("Parsing of Homebrew services failed: \(servicesParsingError)")

            throw HomebrewServiceLoadingError.servicesParsingFailed
        }
    }
}
