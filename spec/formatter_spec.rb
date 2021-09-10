# frozen_string_literal: true
require 'spec_helper'

describe Platon::Formatter do

  let (:formatter) { Platon::Formatter.new }

  it "#to_von" do
    expect(formatter.to_von(1)).to eq 1000000000000000000
    expect(formatter.to_von(nil)).to be_nil
  end

  it "#from_von" do
    expect(formatter.from_von(1000000000000000000)).to eq "1.0"
    expect(formatter.from_von(nil)).to be_nil
  end

  it "#to_gvon" do
    expect(formatter.to_gvon(1)).to eq 1000000000
    expect(formatter.to_von(nil)).to be_nil
  end

  it "#from_gvon" do
    expect(formatter.from_gvon(1000000000)).to eq "1.0"
    expect(formatter.from_gvon(nil)).to be_nil
  end

end
