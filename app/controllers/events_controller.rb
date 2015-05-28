class EventsController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json { render json: Event.all.to_json(include: :tags) }
    end
  end
end
