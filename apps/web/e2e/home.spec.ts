import {test,expect} from './fixtures';
test('bootstrap page',async({page})=>{await page.goto('/');await expect(page.getByRole('heading',{name:'CareGap'})).toBeVisible()});
