require 'omniauth-github'

module OmniAuth
  module Strategies
    class GitHubTeamMember < OmniAuth::Strategies::GitHub
      credentials do
        if team_access_allowed?
          options['teams'].inject({}) do |base, (method_name, org_team_slug)|
            # old method is to specify a team_id, using a deprecated endpoint;
            # new method is to specify organisation and team slug
            org, team_slug = org_team_slug.split('/', 2)
            membership = team_slug ? team_member_new?(org, team_slug) : team_member_old(org)
            base[booleanize_method_name(method_name)] = membership
            base
          end
        else
          {}
        end
      end

      def team_member_new?(org, team_slug)
        access_token.options[:mode] = :header
        response = access_token.get("/orgs/#{org}/teams/#{team_slug}/memberships/#{raw_info['login']}", :headers => { 'Accept' => 'application/vnd.github.v3', 'X-GitHub-Api-Version' => '2022-11-28' })
        response.status == 200 && response.parsed["state"] == "active"
      end

      def team_member_old?(team_id)
        access_token.options[:mode] = :header
        response = access_token.get("/teams/#{team_id}/memberships/#{raw_info['login']}", :headers => { 'Accept' => 'application/vnd.github.v3', 'X-GitHub-Api-Version' => '2022-11-28' })
        response.status == 200 && response.parsed["state"] == "active"
      end

      def team_access_allowed?
        return false unless options['scope']
        team_scopes = ['org', 'read:org', 'write:org', 'admin:org']
        scopes = options['scope'].split(',')
        (scopes & team_scopes).any?
      end

      def booleanize_method_name(method_name)
        return method_name if method_name =~ /\?$/
        return "#{method_name}?"
      end
    end
  end
end

OmniAuth.config.add_camelization "githubteammember", "GitHubTeamMember"
