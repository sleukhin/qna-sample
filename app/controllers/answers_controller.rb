class AnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_question, only: [:create, :accept]
  before_action :load_answer, only: [:update, :destroy, :accept]

  include Voted

  authorize_resource

  respond_to :js
  respond_to :json, only: [:create, :update]

  def create
    @answer = @question.answers.create(answer_params.merge(user_id: current_user.id))

    respond_with @answer do |format|
      format.json do
        PrivatePub.publish_to(
          answers_channel(@question.id),
          answer: (render template: 'answers/create.json.jbuilder'),
          method: 'POST'
        )
      end if @answer.errors.empty?
    end
  end

  def update
    @answer.update(answer_params)
    respond_with @answer do |format|
      format.json do
        PrivatePub.publish_to(
          answers_channel(@answer.question_id),
          answer: (render template: 'answers/update.json.jbuilder'),
          method: 'PATCH'
        )
      end if @answer.errors.empty?
    end
  end

  def destroy
    respond_with(@answer.destroy)
  end

  def accept
    @answer.accept
    @answers = @question.answers.includes(:comments, :attachments)
    respond_with(@answers)
  end

  private

  def load_question
    @question = Question.find(params[:question_id])
  end

  def load_answer
    @answer = Answer.find(params[:id])
  end

  def answers_channel(question_id)
    "/questions/#{question_id}/answers"
  end

  def answer_params
    params.require(:answer).permit(:body, attachments_attributes: [:id, :file, :_destroy])
  end
end
