module ApplicationHelper
  def current_url(extra_params={})
    url_for params.merge(extra_params)
  end
end

