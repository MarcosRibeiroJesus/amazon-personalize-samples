# Contributing to Magic Movie Machine

Thank you for your interest in contributing!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Code Style

- Python: Follow PEP 8
- Terraform: Use `terraform fmt` for formatting
- JavaScript: Use ESLint configuration

## Testing

Before submitting a PR:

1. Test Terraform:
   ```bash
   cd terraform/
   terraform validate
   terraform plan
   ```

2. Test Lambda functions locally:
   ```bash
   python -m pytest lambda_functions/
   ```

## Reporting Issues

If you find a bug, please create an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- AWS region and configuration

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
