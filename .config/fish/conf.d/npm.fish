function npm_set_npmjs
  set -gx NPM_CONFIG_REGISTRY https://registry.npmjs.org
end

function npm_set_cn
  set -gx NPM_CONFIG_REGISTRY https://registry.npmmirror.com/
end

function pnpm_allow_builds
 pnpm config set dangerouslyAllowAllBuilds true
end
