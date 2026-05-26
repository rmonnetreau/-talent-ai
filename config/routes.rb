Rails.application.routes.draw do
  devise_for :users
  root to: "interviews#index"
  get "up" => "rails/health#show", as: :rails_health_check

  resources :interviews, only: [:index, :show, :create, :new, :edit, :update] do
    resources :chats, only: [:create]
  end

  resources :chats, only: :show do
    resources :messages, only: [:create]
  end
end
