class ConferencesController < ApplicationController
  before_action :set_conference, only: %i[ show edit update destroy ]

  # GET /conferences or /conferences.json
  def index
    @conferences = Conference.all
  end

  # GET /conferences/1 or /conferences/1.json
  def show
  end

  # GET /conferences/new
  def new
    @conference = Conference.new
  end

  # GET /conferences/1/edit
  def edit
  end

  # POST /conferences or /conferences.json
  def create
    @conference = Conference.new(conference_params)

    respond_to do |format|
      if @conference.save
        format.html { redirect_to @conference, notice: "Conference was successfully created." }
        format.json { render :show, status: :created, location: @conference }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @conference.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /conferences/1 or /conferences/1.json
  def update
    respond_to do |format|
      if @conference.update(conference_params)
        format.html { redirect_to @conference, notice: "Conference was successfully updated." }
        format.json { render :show, status: :ok, location: @conference }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @conference.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /conferences/1 or /conferences/1.json
  def destroy
    @conference.destroy!

    respond_to do |format|
      format.html { redirect_to conferences_path, status: :see_other, notice: "Conference was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference
      @conference = Conference.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def conference_params
      params.require(:conference).permit(:edition, :location, :start_date, :end_date, :host, :current)
    end
end
