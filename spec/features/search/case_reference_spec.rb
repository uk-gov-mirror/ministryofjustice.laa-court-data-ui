# frozen_string_literal: true

RSpec.feature 'Case reference search', type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  scenario 'with results', stub_case_reference_results: true do
    visit '/'

    choose 'Search by case reference'
    click_button 'Continue'
    fill_in 'search-term-field', with: '05PP1000915'
    click_button 'Search'
    expect(page).to have_text 'Search for "05PP1000915" returned'

    within 'tbody.govuk-table__body' do
      expect(page).to have_content('05PP1000915').twice
    end
  end

  scenario 'with no results', stub_no_results: true do
    visit '/'

    choose 'Search by case reference'
    click_button 'Continue'
    fill_in 'search-term-field', with: '05PP1000915'
    click_button 'Search'
    expect(page).to have_css('.govuk-body', text: 'There are no matching results')
  end
end
