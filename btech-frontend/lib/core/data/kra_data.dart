class KRAData {
  static final List<Map<String, dynamic>> serviceCategories = [
    {
      'title': 'File Returns',
      'icon': 'assessment',
      'description': 'File your annual or monthly tax returns.',
      'services': [
        {
          'name': 'Employment Returns (P9)',
          'type': 'File Returns',
          'subtype': 'Employment',
          'description': 'For employees with a P9 form.',
          'requirements': ['KRA PIN', 'iTax Password', 'P9 Form']
        },
        {
          'name': 'Nil Returns',
          'type': 'File Returns',
          'subtype': 'Nil',
          'description': 'For those with no income to declare.',
          'requirements': ['KRA PIN', 'iTax Password']
        },
        {
          'name': 'Student Returns',
          'type': 'File Returns',
          'subtype': 'Student',
          'description': 'For students with KRA PINs.',
          'requirements': ['KRA PIN', 'iTax Password']
        },
        {
          'name': 'Company Returns',
          'type': 'File Returns',
          'subtype': 'Company',
          'description': 'For registered companies.',
          'requirements': [
            'Company KRA PIN',
            'iTax Password',
            'Profit & Loss Statement'
          ]
        },
      ]
    },
    {
      'title': 'Registration (New PIN)',
      'icon': 'person_add',
      'description': 'Register for a new KRA PIN.',
      'services': [
        {
          'name': 'New Personal PIN',
          'type': 'New PIN',
          'subtype': 'Personal',
          'description': 'For individuals obtaining a PIN for the first time.',
          'requirements': [
            'National ID Copy',
            'Email Address',
            'Phone Number',
            'Mother\'s Name'
          ]
        },
        {
          'name': 'New Organization PIN',
          'type': 'New PIN',
          'subtype': 'Organization',
          'description': 'For companies, partnerships, and NGOS.',
          'requirements': [
            'Certificate of Registration',
            'Director PINs',
            'CR12 Form'
          ]
        },
      ]
    },
    {
      'title': 'Compliance & Certificates',
      'icon': 'verified_user',
      'description': 'Get TCC and other certificates.',
      'services': [
        {
          'name': 'Tax Compliance Certificate',
          'type': 'Compliance',
          'subtype': 'TCC',
          'description': 'Proof of tax compliance for tenders/jobs.',
          'requirements': ['KRA PIN', 'iTax Password']
        },
        {
          'name': 'Amend PIN Details',
          'type': 'Compliance',
          'subtype': 'Amend',
          'description': 'Change email, phone, or name on iTax.',
          'requirements': ['KRA PIN', 'iTax Password', 'Supporting Documents']
        },
      ]
    },
    {
      'title': 'Recovery & Support',
      'icon': 'lock_reset',
      'description': 'Recover lost PINs or Passwords.',
      'services': [
        {
          'name': 'Password Recovery',
          'type': 'Recovery',
          'subtype': 'Password',
          'description': 'Reset your forgotten iTax password.',
          'requirements': ['KRA PIN', 'Email Access']
        },
        {
          'name': 'PIN Recovery',
          'type': 'Recovery',
          'subtype': 'PIN',
          'description': 'Retrieve a forgotten KRA PIN.',
          'requirements': ['National ID Number']
        },
      ]
    },
  ];
}
