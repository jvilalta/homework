# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    render json: { 
      message: "Welcome to RoR PoC", 
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }
  end
end
