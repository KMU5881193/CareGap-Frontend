import {it,expect} from 'vitest';
import {render,screen} from '@testing-library/react';
import {MemoryRouter} from 'react-router';
import {App} from './App';
it('shows the initial workspace',()=>{render(<MemoryRouter><App/></MemoryRouter>);expect(screen.getByRole('heading',{name:'CareGap'})).toBeInTheDocument()});
