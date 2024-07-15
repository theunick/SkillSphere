require 'rails_helper'

RSpec.describe Course, type: :model do
  let(:seller) { Account.create!(name: 'Test Seller', email: 'seller@example.com', role: 'seller') }

  it 'is valid with valid attributes' do
    course = Course.new(
      title: 'My New Course',
      category: 'My New Category',
      description: 'This is a description of my new course',
      price: 99,
      seller: seller
    )
    expect(course).to be_valid
  end

  it 'is not valid without a title' do
    course = Course.new(
      title: nil,
      category: 'My New Category',
      description: 'This is a description of my new course',
      price: 99,
      seller: seller
    )
    expect(course).not_to be_valid
  end

  it 'is not valid without a description' do
    course = Course.new(
      title: 'My New Course',
      category: 'My New Category',
      description: nil,
      price: 99,
      seller: seller
    )
    expect(course).not_to be_valid
  end

  it 'is not valid without a category' do
    course = Course.new(
      title: 'My New Course',
      category: nil,
      description: 'This is a description of my new course',
      price: 99,
      seller: seller
    )
    expect(course).not_to be_valid
  end

  #Default price is 0.0
  it 'is not valid without a price' do
    course = Course.new(
      title: 'My New Course',
      category: 'My New Category',
      description: 'This is a description of my new course',
      price: nil,
      seller: seller
    )
    expect(course).to be_valid
  end

  it 'is not valid with a negative price' do
    course = Course.new(
      title: 'My New Course',
      category: 'My New Category',
      description: 'This is a description of my new course',
      price: -10,
      seller: seller
    )
    expect(course).not_to be_valid
  end

  it 'sets default price to 0.0 if not provided' do
    course = Course.new(
      title: 'My New Course',
      category: 'My New Category',
      description: 'This is a description of my new course',
      seller: seller
    )
    course.valid?
    expect(course.price.to_f).to eq(0.0)
  end

  it 'sets default google_drive_file_ids to an empty array if not provided' do
    course = Course.new(
      title: 'My New Course',
      category: 'My New Category',
      description: 'This is a description of my new course',
      price: 99,
      seller: seller
    )
    expect(course.google_drive_file_ids).to eq('[]')
  end

  describe 'associations' do
    it { should belong_to(:seller).class_name('Account') }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:reports).dependent(:destroy) }
    it { should have_many(:purchases).dependent(:destroy) }
    it { should have_many(:buyers).through(:purchases).source(:account) }
    it { should have_many(:cart_items).dependent(:destroy) }
  end

  describe 'scopes' do
    it 'includes only visible courses' do
      visible_course = Course.create!(
        title: 'Visible Course',
        category: 'Category',
        description: 'Visible course description',
        price: 99,
        seller: seller,
        hidden: false
      )

      hidden_course = Course.create!(
        title: 'Hidden Course',
        category: 'Category',
        description: 'Hidden course description',
        price: 99,
        seller: seller,
        hidden: true
      )

      expect(Course.visible).to include(visible_course)
      expect(Course.visible).not_to include(hidden_course)
    end
  end

  describe 'custom methods' do
    it 'calculates total earnings' do
      course = Course.create!(
        title: 'My New Course',
        category: 'My New Category',
        description: 'This is a description of my new course',
        price: 99,
        seller: seller
      )

      Purchase.create!(account: seller, course: course)
      Purchase.create!(account: seller, course: course)

      expect(course.total_earnings).to eq(198.0)
    end

    it 'calculates purchases count' do
      course = Course.create!(
        title: 'My New Course',
        category: 'My New Category',
        description: 'This is a description of my new course',
        price: 99,
        seller: seller
      )

      Purchase.create!(account: seller, course: course)
      Purchase.create!(account: seller, course: course)

      expect(course.purchases_count).to eq(2)
    end

    it 'calculates views count' do
      course = Course.create!(
        title: 'My New Course',
        category: 'My New Category',
        description: 'This is a description of my new course',
        price: 99,
        seller: seller
      )

      course.impressions.create!
      course.impressions.create!

      expect(course.views_count).to eq(2)
    end
  end
end
