{
	description = "Setup for CHBE 431 De-Novo Protein Design Assignment";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs =
		{ self, nixpkgs, ... }:
		let
			system = "x86_64-linux";
			pkgs = nixpkgs.legacyPackages.${system};

			pythonEnv = pkgs.python3.withPackages (
				pypkgs: with pypkgs; [
					pandas
				]
			);

		in
		{
			devShells.${system}.default = pkgs.mkShell {
				packages = [
					pythonEnv
				];
			};
		};
}
