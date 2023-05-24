Pod::Spec.new do |s|
  s.name                = "HQRouter"
  s.version             = "0.1.0"
  s.summary             = "Simple iOS Router SDK"
  s.homepage            = "https://github.com/QuasimodoHe/HQRouter"
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.author              = { "QuasimodoHe" => "qhe95hunan@sina.com" }
  s.source              = { :git => "https://github.com/QuasimodoHe/HQRouter.git", :tag => s.version.to_s }
  s.platform            = :ios, "9.0"
  s.source_files        = "HQRouter/**/*.{h,m,swift}"
  s.requires_arc        = true
end
