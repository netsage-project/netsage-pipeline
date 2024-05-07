# example_spec.rb
#
#
class StringCalculator

  def self.add(input)
    4
  end
end

describe StringCalculator do

  describe ".add" do
    context "given an empty string" do
      it "returns zero" do
        expect(StringCalculator.add("4")).to eq(4)
      end
    end
  end
end
