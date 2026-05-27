Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "pages#home"

  resources :interviews, only: [:index, :show, :create, :new, :edit, :update, :destroy] do
    resources :chats, only: [:create, :new]
  end

  resource :profile, only: [:show, :new, :edit, :create, :update]

  resources :chats, only: :show do
    resources :messages, only: [:create]
    resources :feedbacks, only: [:create]
  end
end
