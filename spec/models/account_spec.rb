require 'spec_helper'

describe Account do
  subject { create(:account, locked: "10.0".to_d, balance: "10.0") }

  it { expect(subject.amount).to be_d '20' }
  it { expect(subject.sub_funds("1.0".to_d).balance).to eql "9.0".to_d }
  it { expect(subject.plus_funds("1.0".to_d).balance).to eql "11.0".to_d }
  it { expect(subject.unlock_funds("1.0".to_d).locked).to eql "9.0".to_d }
  it { expect(subject.unlock_funds("1.0".to_d).balance).to eql "11.0".to_d }
  it { expect(subject.lock_funds("1.0".to_d).locked).to eql "11.0".to_d }
  it { expect(subject.lock_funds("1.0".to_d).balance).to eql "9.0".to_d }

  it { expect(subject.unlock_and_sub_funds('1.0'.to_d, locked: '1.0'.to_d).balance).to be_d '10' }
  it { expect(subject.unlock_and_sub_funds('1.0'.to_d, locked: '1.0'.to_d).locked).to be_d '9' }

  it { expect(subject.sub_funds("0.1".to_d).balance).to eql "9.9".to_d }
  it { expect(subject.plus_funds("0.1".to_d).balance).to eql "10.1".to_d }
  it { expect(subject.unlock_funds("0.1".to_d).locked).to eql "9.9".to_d }
  it { expect(subject.unlock_funds("0.1".to_d).balance).to eql "10.1".to_d }
  it { expect(subject.lock_funds("0.1".to_d).locked).to eql "10.1".to_d }
  it { expect(subject.lock_funds("0.1".to_d).balance).to eql "9.9".to_d }

  it { expect(subject.unlock_and_sub_funds('0.1'.to_d, locked: '1.0'.to_d).balance).to be_d '10.9' }
  it { expect(subject.unlock_and_sub_funds('0.1'.to_d, locked: '1.0'.to_d).locked).to be_d '9' }

  it { expect(subject.sub_funds("10.0".to_d).balance).to eql "0.0".to_d }
  it { expect(subject.plus_funds("10.0".to_d).balance).to eql "20.0".to_d }
  it { expect(subject.unlock_funds("10.0".to_d).locked).to eql "0.0".to_d }
  it { expect(subject.unlock_funds("10.0".to_d).balance).to eql "20.0".to_d }
  it { expect(subject.lock_funds("10.0".to_d).locked).to eql "20.0".to_d }
  it { expect(subject.lock_funds("10.0".to_d).balance).to eql "0.0".to_d }

  it { expect{subject.sub_funds("11.0".to_d)}.to raise_error }
  it { expect{subject.lock_funds("11.0".to_d)}.to raise_error }
  it { expect{subject.unlock_funds("11.0".to_d)}.to raise_error }

  it { expect{subject.unlock_and_sub_funds('1.1'.to_d, locked: '1.0'.to_d)}.to raise_error }

  it { expect{subject.sub_funds("-1.0".to_d)}.to raise_error }
  it { expect{subject.plus_funds("-1.0".to_d)}.to raise_error }
  it { expect{subject.lock_funds("-1.0".to_d)}.to raise_error }
  it { expect{subject.unlock_funds("-1.0".to_d)}.to raise_error }
  it { expect{subject.sub_funds("0".to_d)}.to raise_error }
  it { expect{subject.plus_funds("0".to_d)}.to raise_error }
  it { expect{subject.lock_funds("0".to_d)}.to raise_error }
  it { expect{subject.unlock_funds("0".to_d)}.to raise_error }

  it "expect to set reason" do
    subject.plus_funds("1.0".to_d)
    expect(subject.last_version.reason.to_sym).to eql Account::UNKNOWN
  end

  it "expect to set ref" do
    ref = stub(:id => 1)

    subject.plus_funds("1.0".to_d, ref: ref)

    expect(subject.last_version.modifiable_id).to eql 1
    expect(subject.last_version.modifiable_type).to eql Mocha::Mock.name
  end

  describe "double operation" do
    let(:strike_volume) { "10.0".to_d }
    let(:account) { create(:account) }

    it "expect double operation funds" do
      expect do
        account.plus_funds(strike_volume, reason: Account::STRIKE_ADD)
        account.sub_funds(strike_volume, reason: Account::STRIKE_FEE)
      end.to_not change{account.balance}
    end

    it "expect double operation funds to add versions" do
      expect do
        account.plus_funds(strike_volume, reason: Account::STRIKE_ADD)
        account.sub_funds(strike_volume, reason: Account::STRIKE_FEE)
      end.to change{account.reload.versions.size}.from(0).to(2)
    end
  end

  describe "#payment_address" do
    it { expect(subject.payment_address).not_to be_nil }
    it { expect(subject.payment_address).to be_is_a(PaymentAddress) }
  end

  describe "#versions" do
    let(:account) { create(:account) }

    context 'when account add funds' do
      subject { account.plus_funds("10".to_d, reason: Account::WITHDRAW).last_version }

      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "0" }
      it { expect(subject.balance).to be_d "10" }
      it { expect(subject.amount).to be_d "110" }
      it { expect(subject.fee).to be_d "0" }
      it { expect(subject.fun).to eq 'plus_funds' }
    end

    context 'when account add funds with fee' do
      subject { account.plus_funds("10".to_d, fee: '1'.to_d, reason: Account::WITHDRAW).last_version }

      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "0" }
      it { expect(subject.balance).to be_d "10" }
      it { expect(subject.amount).to be_d "110" }
      it { expect(subject.fee).to be_d "1" }
      it { expect(subject.fun).to eq 'plus_funds' }
    end

    context 'when account sub funds' do
      subject { account.sub_funds("10".to_d, reason: Account::WITHDRAW).last_version }
      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "0" }
      it { expect(subject.balance).to be_d "-10" }
      it { expect(subject.amount).to be_d "90" }
      it { expect(subject.fee).to be_d "0" }
      it { expect(subject.fun).to eq 'sub_funds' }
    end

    context 'when account sub funds with fee' do
      subject { account.sub_funds("10".to_d, fee: '1'.to_d, reason: Account::WITHDRAW).last_version }
      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "0" }
      it { expect(subject.balance).to be_d "-10" }
      it { expect(subject.amount).to be_d "90" }
      it { expect(subject.fee).to be_d "1" }
      it { expect(subject.fun).to eq 'sub_funds' }
    end

    context 'when account lock funds' do
      subject { account.lock_funds("10".to_d, reason: Account::WITHDRAW).last_version }
      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "10" }
      it { expect(subject.balance).to be_d "-10" }
      it { expect(subject.amount).to be_d "100.0" }
    end

    context 'when account unlock funds' do
      let(:account) { create(:account, locked: "10".to_d) }
      subject { account.unlock_funds("10".to_d, reason: Account::WITHDRAW).last_version }
      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "-10" }
      it { expect(subject.balance).to be_d "10" }
      it { expect(subject.amount).to be_d "110" }
    end

    context 'when account unlock and sub funds' do
      let(:account) { create(:account, balance: '10'.to_d, locked: "10".to_d) }
      subject { account.unlock_and_sub_funds("10".to_d, locked: "10".to_d, reason: Account::WITHDRAW).last_version }
      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "-10" }
      it { expect(subject.balance).to be_d "0" }
      it { expect(subject.amount).to be_d "10.0" }
      it { expect(subject.fee).to be_d "0" }
      it { expect(subject.fun).to eq 'unlock_and_sub_funds' }
    end

    context 'when account unlock and sub funds with fee' do
      let(:account) { create(:account, balance: '10'.to_d, locked: "10".to_d) }
      subject { account.unlock_and_sub_funds("10".to_d, fee: '1'.to_d, locked: "10".to_d, reason: Account::WITHDRAW).last_version }
      it { expect(subject.reason.withdraw?).to be_true }
      it { expect(subject.locked).to be_d "-10" }
      it { expect(subject.balance).to be_d "0" }
      it { expect(subject.amount).to be_d "10.0" }
      it { expect(subject.fee).to be_d "1" }
      it { expect(subject.fun).to eq 'unlock_and_sub_funds' }
    end
  end

  describe "#examine" do
    let(:account) { create(:account, locked: "0.0".to_d, balance: "0.0") }

    context "account without any account versions" do
      it "returns true" do
        expect(account.examine).to be_true
      end

      it "returns false when account changed without versions" do
        account.update_attribute(:balance, 5000.to_d)
        expect(account.examine).to be_false
      end
    end

    context "account with account versions" do
      before do
        account.plus_funds("100.0".to_d)
        account.sub_funds("1.0".to_d)
        account.plus_funds("12.0".to_d)
        account.lock_funds("12.0".to_d)
        account.unlock_funds("1.0".to_d)
        account.lock_funds("1.0".to_d)
        account.lock_funds("1.0".to_d)
      end

      it "returns true" do
        expect(account.examine).to be_true
      end

      it "returns false when account balance doesn't match versions" do
        account.update_attribute(:balance, 5000.to_d)
        expect(account.examine).to be_false
      end

      it "returns false when account versions were changed" do
        account.versions.load.sample.update_attribute(:amount, 50.to_d)
        expect(account.examine).to be_false
      end
    end
  end

  describe "#change_balance_and_locked" do
    it "should update balance and locked funds in memory" do
      subject.change_balance_and_locked "-10".to_d, "10".to_d
      subject.balance.should be_d('0')
      subject.locked.should be_d('20')
    end

    it "should update balance and locked funds in db" do
      subject.change_balance_and_locked "-10".to_d, "10".to_d
      subject.reload
      subject.balance.should be_d('0')
      subject.locked.should be_d('20')
    end
  end

end
