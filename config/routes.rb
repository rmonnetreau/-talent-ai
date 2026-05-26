Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "pages#home"

  resources :interviews, only: [:index, :show, :create, :new, :edit, :update] do
    resources :chats, only: [:create, :new, :show, :edit]
  end

  resources :chats, only: :show do
    resources :messages, only: [:create]
  end
end
