FROM microsoft/dotnet:2.1-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80

FROM microsoft/dotnet:2.1-sdk AS build
WORKDIR /src
COPY . .
WORKDIR /src/src/Services/Basket/Basket.API
RUN dotnet restore -nowarn:msb3202,nu1503
RUN dotnet build --no-restore -c Release -o /app

FROM build as unittest
LABEL test=true
RUN dotnet tool install dotnet-reportgenerator-globaltool --version 4.0.6 --tool-path /tools
WORKDIR /src/src/Services/Basket/Basket.UnitTests
RUN dotnet test --logger "trx;LogFileName=test_results.xml" /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:CoverletOutput=./TestResults/coverage/ 
RUN ls -lar TestResults
WORKDIR /TestResults
RUN cp -r /src/src/Services/Basket/Basket.UnitTests/TestResults .

FROM build as testrunner
WORKDIR /src/src/Services/Basket/Basket.UnitTests
ENTRYPOINT ["dotnet", "test", "--logger:trx"]

FROM build AS publish
RUN dotnet publish --no-restore -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Basket.API.dll"]
