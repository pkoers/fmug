class SchedulesController < ApplicationController
  before_action :require_admin, except: :agenda
  before_action :set_schedule, only: %i[ show edit update destroy ]

  # GET /schedules or /schedules.json
  def index
    @schedules = Schedule.order(:day, :time)
  end

  def agenda
    @schedules = Schedule.order(:day, :time)
  end
  # GET /schedules/1 or /schedules/1.json
  def show
  end

  # GET /schedules/new
  def new
    @schedule = Schedule.new
  end

  # GET /schedules/1/edit
  def edit
  end

  # POST /schedules or /schedules.json
  def create
    permitted_schedule_params = schedule_params
    warn "[CI DIAGNOSTICS] submitted schedule_params=#{permitted_schedule_params.to_h.inspect}" if ci_diagnostics_enabled?
    @schedule = Schedule.new(permitted_schedule_params)

    respond_to do |format|
      if @schedule.save
        format.html { redirect_to @schedule, notice: "Schedule was successfully created." }
        format.json { render :show, status: :created, location: @schedule }
      else
        warn "[CI DIAGNOSTICS] @schedule.errors.full_messages=#{@schedule.errors.full_messages.inspect}" if ci_diagnostics_enabled?
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /schedules/1 or /schedules/1.json
  def update
    respond_to do |format|
      if @schedule.update(schedule_params)
        format.html { redirect_to @schedule, notice: "Schedule was successfully updated." }
        format.json { render :show, status: :ok, location: @schedule }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schedules/1 or /schedules/1.json
  def destroy
    @schedule.destroy!

    respond_to do |format|
      format.html { redirect_to schedules_path, status: :see_other, notice: "Schedule was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_schedule
      @schedule = Schedule.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def schedule_params
      params.require(:schedule).permit(:conference_id, :time, :length, :description, :day)
    end

    def ci_diagnostics_enabled?
      Rails.env.test? && ENV["CI"].present?
    end
end
