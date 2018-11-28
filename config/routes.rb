Spotlight::Oaipmh::Resources::Engine.routes.draw do
  resources :exhibits, path: '/', only: [] do
      resource :harvester, controller: :"spotlight/resources/harvester", only: [:create, :update]
    end
end
