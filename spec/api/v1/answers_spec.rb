require 'rails_helper'

describe 'Answer API' do
  let(:user) { create(:user) }
  let!(:question) { create(:question, user: user) }

  describe 'GET/index' do
    it_behaves_like 'api resource'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: user.id) }
      let!(:answers) { create_list(:answer, 2, user: user, question: question) }
      let(:answer) { answers.first }

      before do
        get(
          "/api/v1/questions/#{question.id}/answers",
          format: :json,
          access_token: access_token.token)
      end

      it 'returns 200 status code' do
        expect(response).to be_success
      end

      it 'returns list of answers' do
        expect(response.body).to have_json_size(2).at_path('answers')
      end

      %w(id body created_at updated_at user_id accepted).each do |attr|
        it "contains answer object #{attr}" do
          expect(response.body).to(
            be_json_eql(answer.send(attr.to_sym).to_json).at_path("answers/0/#{attr}")
          )
        end
      end
    end

    def do_request(options = {})
      get "/api/v1/questions/#{question.id}/answers", { format: :json }.merge(options)
    end
  end

  describe 'GET/show' do
    let!(:answer) { create(:answer, user: user, question: question) }
    let!(:comment) { create(:comment, user: user, commentable: answer) }
    let!(:attachment) { create(:attachment, attachmentable: answer) }

    it_behaves_like 'api resource'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: user.id) }

      before do
        get(
          "/api/v1/questions/#{question.id}/answers/#{answer.id}",
          format: :json,
          access_token: access_token.token)
      end

      it 'returns 200 status code' do
        expect(response).to be_success
      end

      %w(id body created_at updated_at user_id accepted).each do |attr|
        it "contains answer object #{attr}" do
          expect(response.body).to(
            be_json_eql(answer.send(attr.to_sym).to_json).at_path("answer/#{attr}")
          )
        end
      end

      it_behaves_like 'it has comments json' do
        let(:resource_name) { 'answer' }
      end

      it_behaves_like 'it has attachments json' do
        let(:resource_name) { 'answer' }
      end
    end

    def do_request(options = {})
      get "/api/v1/questions/#{question.id}/answers/#{answer.id}", { format: :json }.merge(options)
    end
  end

  describe 'POST/create' do
    it_behaves_like 'api resource'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: user.id) }

      let(:post_answer) do
        post(
          "/api/v1/questions/#{question.id}/answers",
          format: :json,
          access_token: access_token.token,
          question_id: question.id,
          answer: attributes_for(:answer))
      end

      it 'returns status 201' do
        post_answer
        expect(response.status).to eq 201
      end

      it 'saves the new answer in the database' do
        expect { post_answer }.to change(Answer, :count).by(1)
      end
    end

    def do_request(options = {})
      post(
        "/api/v1/questions/#{question.id}/answers",
        { format: :json, question_id: question.id, answer: attributes_for(:answer) }.merge(options)
      )
    end
  end
end
