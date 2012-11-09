
module PatchesHelper

  def patch_kinds
    { "security" => 'kupdateapplet_red.png',
      "important" => 'kupdateapplet_yellow.png',
      "normal" => 'kupdateapplet_yellow.png',
      "optional" => 'kupdateapplet_optional.png',
      "low" => 'kupdateapplet_green.png',
      "enhancement" => 'kupdateapplet_optional.png'
    }
  end

end